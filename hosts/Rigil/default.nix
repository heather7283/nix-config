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

    net.core.default_qdisc="fq";
    net.ipv4.tcp_congestion_control="bbr";
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

  services.jmusicbot = {
    enable = true;
    configFile = config.sops.secrets."jmusicbot-config.txt".path;
  };

  networking = {
    hostName = "Rigil";
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

    # Wireguard
    wireguard = {
      useNetworkd = true;
      interfaces.wg0 = {
        ips = [ "10.200.200.1/24" ];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets."wireguard/private-key";
        peers = let
          mkPeer = pubkey: ip: { publicKey = pubkey; ip = "10.200.200.${ip}/32"; };
        in [
          (mkPeer "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=" 2) # fa506ih
          (mkPeer "n0PDD0Ro8A34wG5yjoaC71JzyvrUksqd1AFYpyDyQl4=" 10) # qblue
          (mkPeer "TG4GGODEYH0JUunFv+kXcpYbNLihODXcgR7X3b3Tbgw=" 20) # mi9l
          (mkPeer "0ihUeP3zg9CmGjT4evfbcO1x2bnL7yHaytrttT1Mszs=" 3) # and pc
          (mkPeer "KIRAECnHHExL8mpSgg2Ie9M9Bs78Wuctvz3hnK+bA28=" 197) # kir linux
          (mkPeer "KIRAwgVP50u4P2jqBisGSqoZ4nQpfaKJ5HyvmuvdQ10=" 198) # kir windows
          (mkPeer "kIRLBInjS/jHm11QMI55IEUV0wxewBwXgDnD6Uja0zk=" 199) # kir laptop
          (mkPeer "yaRaK3hyUKfCZvQ8QGTnv490o5Q/Ty4zYPHUPnfAVgw=" 100) # yar ubuntu
          (mkPeer "YAnDnt7Nebfdsdts2ugHZHUo2hmqL0pD//jpb9zwPmQ=" 41) # proxima
        ];
      };
    };
    networking.nat = {
      enable = true;
      internalInterfaces = [ "wg0" ];
      internalIPs = [ "10.200.200.0/24" ];
      externalInterface = "ens3";
      forwardPorts = [
        { sourcePort = 8000; destination = "10.200.200.2"; }
        { sourcePort = 4533; destination = "10.200.200.10"; }
        { sourcePort = 50123; destination = "10.200.200.198"; }
      ]
    };
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

