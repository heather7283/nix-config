{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  users.users.heather = {
    hashedPasswordFile = config.sops.secrets."users/heather/password".path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBEQ9exoJqJbq3xbIsCyZUO1NfzgM21yjHbyFzQTOpKt"
    ];
  };

  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    vm = {
      # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
      swappiness = 180;
      watermark_boost_factor = 0;
      watermark_scale_factor = 125;
      page-cluster = 0;
    };
    # required for wireguard routing
    net.ipv4.ip_forward = 1;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 200;
  };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # List services that you want to enable:
  services.openssh = {
    enable = true;
    listenAddresses = [{ addr = "10.200.200.41"; port = 37643; }];
    openFirewall = false; # prevent 22 from being opened
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  systemd.services.sshd.bindsTo = [ "wireguard-wg0.target" ];
  systemd.services.sshd.after = [ "wireguard-wg0.target" ];

  # network usage monitoring
  services.vnstat.enable = true;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = lib.mkForce false;

  # configure networking
  networking = {
    enableIPv6 = false;
    useDHCP = true;
    nftables.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [ "wg0" ];
    };
    wireguard.interfaces.wg0 = {
      ips = [ "10.200.200.41/32" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wireguard/private-key".path;
      peers = [
        {
          # fa506ih
          publicKey = "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=";
          allowedIPs = [ "10.200.200.2/32" ];
        }
        {
          # pluto; rigil reachable through pluto
          publicKey = "pLUtoUowRkkp4a00eimV7oBhUzq4JgHk9OIi5oP7wTA=";
          allowedIPs = [ "10.200.200.50/32" "10.200.200.1/32" ];
        }
      ];
    };
  };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };
}
