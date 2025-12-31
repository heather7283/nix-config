{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  users.mutableUsers = false;
  users.users.heather.hashedPasswordFile = config.sops.secrets."users/heather/password".path;

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
    priority = 200;
  };

  networking.hostName = "Proxima"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

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
    settingsFile = config.sops.secrets."xray-config.jsonc".path;
  };
  systemd.services.xray.serviceConfig.LogsDirectory = "xray";

  # network usage monitoring
  services.vnstat.enable = true;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = lib.mkForce false;

  # configure networking
  networking = {
    enableIPv6 = false;
    useDHCP = true;
    resolvconf = {
      enable = false;
      useLocalResolver = true;
    };
    nftables.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 443 37643 ];
      allowedUDPPorts = [ ];
      logRefusedConnections = false; # pollutes logs a lot
    };
    wireguard.interfaces.wg0 = {
      ips = [ "10.200.200.41/32" ];
      privateKeyFile = config.sops.secrets."wireguard/private-key".path;
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
      timerConfig.OnCalendar = "hourly";
    };

    services."dump-vnstat-to-serial" = {
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ vnstat ];
      script = ''
        while :; do
          printf 'VNSTAT;%d;%s\n' "$(date +%s)" "$(vnstat --iface enp7s0 --oneline b)" >/dev/ttyS3
          sleep 60
        done
      '';
    };
  };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };
}
