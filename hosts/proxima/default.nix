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
  systemd.services.sshd.requires = [ "sys-devices-virtual-net-wg0.device" ];

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
      trustedInterfaces = [ "wg0" ];
      allowedTCPPorts = [ 443 ];
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
        persistentKeepalive = 25;
      }];
    };
  };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };
}
