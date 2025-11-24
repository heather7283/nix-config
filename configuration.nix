# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, nix-secrets, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  sops = let xfiles = nix-secrets.paths.proxima; in {
    age = {
      sshKeyPaths = lib.mkForce []; # not needed in my config
      keyFile = "${config.users.users.heather.home}/.config/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      "wireguard_private_key" = {
        sopsFile = xfiles.wireguard;
        key = "private_key";
      };
      "xray_config.json" = {
        sopsFile = xfiles.xray;
        format = "json";
        key = "";
      };
    };
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only
  boot.kernelParams = [ "console=ttyS0" ];
  boot.growPartition = true;

  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    vm = {
      # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
      swappiness = 180;
      watermark_boost_factor = 0;
      watermark_scale_factor = 125;
      page-cluster = 0;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  networking.hostName = "Proxima"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "C.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    heather = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW47TMs+tXJEl6bY0FGd54kf5DM/g21mfA5tij5JNJc heather@FA506IH"
      ];
      shell = pkgs.zsh;
      packages = with pkgs; [ fzf btop ];
    };
  };

  # List packages installed in system profile.
  programs.zsh = {
    enable = true;
    shellInit = builtins.concatStringsSep "\n" [
      "export ZDOTDIR=\"$HOME\"/.config/zsh/" # zshenv
    ];
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    configure = {
      customRC = ''
        set modeline
        set expandtab
        set tabstop=4
        set shiftwidth=4
        set number
        set autochdir

        lua << EOF
        vim.api.nvim_set_hl(0, "TrailingWhitespace", { bg = "red", ctermbg = "red" })
        vim.api.nvim_create_autocmd({"BufWinEnter", "InsertLeave"}, {
          pattern = "*",
          callback = function()
            if vim.bo.buftype == "" then
              vim.fn.clearmatches()
              vim.fn.matchadd('TrailingWhitespace', [[\v\s+$|^\s+$]])
            end
          end
        })
        EOF
      '';
    };
  };
  environment.systemPackages = with pkgs; [
    git
    age
    sops
    curl
    rsync
    python3
  ];

  # List services that you want to enable:
  services.openssh = {
    enable = true;
    listenAddresses = [{ addr = "0.0.0.0"; port = 37643; }];
    openFirewall = false; # prevent 22 from being opened
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.xray = {
    enable = true;
    settingsFile = config.sops.secrets."xray_config.json".path;
  };
  systemd.services.xray.serviceConfig.LogsDirectory = "xray";

  # network usage monitoring
  services.vnstat.enable = true;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce([]);
  services.nscd.enable = false;

  # configure networking
  networking = {
    enableIPv6 = false;
    useDHCP = true;
    resolvconf = {
      enable = false;
      useLocalResolver = true;
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 443 37643 ];
      allowedUDPPorts = [ ];
      logRefusedConnections = false; # pollutes logs a lot
    };
    wireguard.interfaces.wg0 = {
      ips = [ "10.200.200.41/32" ];
      privateKeyFile = config.sops.secrets."wireguard_private_key".path;
      peers = [{
        publicKey = "i+NTNzzUn9vuRsmfyidoHgWtqKgb73OOQnajCX86b0c=";
        endpoint = "127.0.0.1:51821";
        allowedIPs = [ "10.200.200.0/24" ];
      }];
    };
  };
  # xray, see https://discourse.nixos.org/t/why-cant-i-get-dns-nameservers-to-stick/59132
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
  '';

  systemd = {
    # https://github.com/systemd/systemd/issues/5356
    extraConfig = lib.foldl (prev: cur: prev + cur + "\n") "" [
      "StatusUnitFormat=combined"
    ];

    services."check-egress-traffic" = {
      path = with pkgs; [ vnstat jq ];
      script = ''
        set -eu

        tx_bytes="$(vnstat --json m 1 \
                    | jq '.interfaces[] | select(.name == "enp7s0").traffic.month[].tx')"
        tx_gigs=$((tx_bytes / 1024 / 1024 / 1024))

        if [ "$tx_gigs" -ge 90 ]; then
          printf "WARNING: %s GiB (%s B) transferred!\n" "$tx_gigs" "$tx_bytes"
        fi
      '';
    };
    timers."check-egress-traffic" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };

  environment.etc."inputrc".text = "set editing-mode vi";

  system.stateVersion = "25.11"; # Do not change
}
# vim: ts=2 sw=2:

