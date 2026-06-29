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
    # required for wireguard routing
    net.ipv4.ip_forward = 1;
  };

  ext.zram.enable = true;

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
      allowedTCPPorts = [ 37643 ]; # sshd
    };
    wireguard.interfaces.wg0 = {
      ips = [ "10.20.30.41/32" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wireguard/private-key".path;
      peers = [
        {
          # fa506ih
          publicKey = "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=";
          allowedIPs = [ "10.20.30.2/32" ];
        }
        {
          # pluto; rigil reachable through pluto
          publicKey = "pLUtoUowRkkp4a00eimV7oBhUzq4JgHk9OIi5oP7wTA=";
          allowedIPs = [ "10.20.30.50/32" "10.20.30.1/32" ];
        }
      ];
    };
  };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };
}
