{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    # Uncomment the next line to enable packet forwarding for IPv4
    net.ipv4.ip_forward=1;

    # https://unix.stackexchange.com/a/112232
    net.ipv4.conf.all.route_localnet=1;

    net.core.default_qdisc=fq;
    net.ipv4.tcp_congestion_control=bbr;
  };

  services.openssh = {
    enable = true;
    listenAddresses = [{ addr = "0.0.0.0"; port = 60322; }];
    openFirewall = false; # prevent 22 from being opened?
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
  system.nssModules = lib.mkForce([]);
  services.nscd.enable = false;

  services.resolved.enable = lib.mkForce false;

  networking = {
    hostName = "Toliman";
    useDHCP = false;
    useNetworkd = true;
    resolvconf = {
      enable = false;
      useLocalResolver = true;
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        443 # https
        60322 # ssh
        4533 # navidrome
        8000 # python -m http.server
      ];
      allowedUDPPorts = [
        51820 # wireguard
      ];
      interfaces.wg0 = {
        allowedTCPPorts = [ 53 ]; # dns
        allowedUDPPorts = [ 53 ]; # dns
      };
      logRefusedConnections = false; # pollutes logs a lot
    };
    wg-quick.interfaces.wg0.configFile = config.sops.secrets."wg-quick-wg0.conf".path;
  };
  # xray, see https://discourse.nixos.org/t/why-cant-i-get-dns-nameservers-to-stick/59132
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
  '';

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
  # things I have to do to not flash my VPS' public IP on github :|
  sops.templates."ens3.network".content = let ip = config.sops.placeholder."ip"; in ''
    [Match]
    Name=ens3

    [Network]
    Address=${ip}/32
    Gateway=10.0.0.1

    [Route]
    Gateway=10.0.0.1
    GatewayOnLink=true
  '';
  environment.etc."systemd/network/ens3.network" = {
    source = config.sops.templates."ens3.network".path;
    mode = "0644";
  };
}

