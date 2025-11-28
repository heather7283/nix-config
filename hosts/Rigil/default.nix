{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  services.openssh = {
    enable = true;
    listenAddresses = [{ addr = "0.0.0.0"; port = 60322; }];
    # prevents 22 from being opened, must manually open actual port in firewall
    openFirewall = false;
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

  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    # DO NOT REMOVE
    net.ipv4.ip_forward=1;
    # https://unix.stackexchange.com/a/112232
    net.ipv4.conf.all.route_localnet=1;

    net.core.default_qdisc="fq";
    net.ipv4.tcp_congestion_control="bbr";
  };

  networking = {
    hostName = "Rigil";

    useDHCP = false;
    useNetworkd = true;

    # DO NOT USE. This garbage does not work with port forward
    nftables.enable = false;

    enableIPv6 = false;

    resolvconf = {
      enable = false;
      useLocalResolver = true;
    };

    firewall = {
      enable = true;
      trustedInterfaces = [ "wg0" ];
      allowedTCPPorts = [
        443 # https
        60322 # ssh
      ];
      allowedUDPPorts = [
        51820 # wireguard
      ];
      logRefusedConnections = false; # pollutes logs a lot
    };

    # Wireguard
    wg-quick.interfaces.wg0.configFile = config.sops.secrets."wg-quick-wg0.conf".path;

    #wireguard = {
    #  useNetworkd = true;
    #  interfaces.wg0 = {
    #    ips = [ "10.200.200.1/24" ];
    #    listenPort = 51820;
    #    privateKeyFile = config.sops.secrets."wireguard/private-key".path;
    #    peers = with builtins; let
    #      mkPeer = key: ip: { publicKey = key; allowedIPs = [ "10.200.200.${toString ip}/32" ]; };
    #    in [
    #      (mkPeer "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=" 2) # fa506ih
    #      (mkPeer "n0PDD0Ro8A34wG5yjoaC71JzyvrUksqd1AFYpyDyQl4=" 10) # qblue
    #      (mkPeer "TG4GGODEYH0JUunFv+kXcpYbNLihODXcgR7X3b3Tbgw=" 20) # mi9l
    #      (mkPeer "0ihUeP3zg9CmGjT4evfbcO1x2bnL7yHaytrttT1Mszs=" 3) # and pc
    #      (mkPeer "KIRAECnHHExL8mpSgg2Ie9M9Bs78Wuctvz3hnK+bA28=" 197) # kir linux
    #      (mkPeer "KIRAwgVP50u4P2jqBisGSqoZ4nQpfaKJ5HyvmuvdQ10=" 198) # kir windows
    #      (mkPeer "kIRLBInjS/jHm11QMI55IEUV0wxewBwXgDnD6Uja0zk=" 199) # kir laptop
    #      (mkPeer "yaRaK3hyUKfCZvQ8QGTnv490o5Q/Ty4zYPHUPnfAVgw=" 100) # yar ubuntu
    #      (mkPeer "YAnDnt7Nebfdsdts2ugHZHUo2hmqL0pD//jpb9zwPmQ=" 41) # proxima
    #    ];
    #  };
    #};

    # DO NOT USE NIXOS' BUILTIN NAT AND PORT FORWARDING OPTIONS!!!
    # They do NOT work how I want. I spent 2 hours fighting it in the past.
    # Do not repeat my past mistakes. Just don't bother with this shit.
    # You have iptables, they work, DO NOT FIX WHAT IS NOT BROKEN.
    #nat = {
    #  enable = true;
    #  internalInterfaces = [ "wg0" ];
    #  internalIPs = [ "10.200.200.0/24" ];
    #  externalInterface = "ens3";
    #  externalIP = "62.109.25.255";
    #  forwardPorts = with builtins; let
    #    mkForwardPorts = arr: concatMap
    #      (elem: concatMap
    #        (proto: let dst = if elem?dst then elem.dst else elem.src; in [{
    #          sourcePort = elem.src;
    #          destination = "${elem.ip}:${toString dst}";
    #          proto = proto;
    #        }])
    #        elem.protos)
    #      arr
    #    ;
    #  in mkForwardPorts [
    #    { ip = "10.200.200.2"; src = 8001; protos = [ "tcp" "udp" ]; }
    #    { ip = "10.200.200.10"; src = 4533; protos = [ "tcp" "udp" ]; }
    #    { ip = "10.200.200.198"; src = 50123; protos = [ "tcp" "udp" ]; }
    #  ];
    #};
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

