{ config, lib, pkgs, ... }:

with builtins; let
  wrapIptables = commands: map (cmd: "${pkgs.iptables}/bin/iptables " + cmd) commands;

  cmdToIptablesArg = cmd:
    if cmd == "up" then "-I" else if cmd == "down" then "-D" else throw "cmd must be up or down"
  ;

  mkWgForwardRule = cmd: ip: _outer: _inner: proto: let
    outer = toString _outer;
    inner = toString _inner;
    arg = cmdToIptablesArg cmd;
  in wrapIptables [
    # Whitelist outer port in the firewall
    "${arg} INPUT -p ${proto} --dport ${outer} -j ACCEPT"
    # Rewrite destination
    "-t nat ${arg} PREROUTING -p ${proto} --dport ${outer} -j DNAT --to-destination ${ip}:${inner}"
    # Fix return address
    "-t nat ${arg} POSTROUTING -p ${proto} -d ${ip} --dport ${inner} -j MASQUERADE"
    # Redirect traffic from local machine too
    "-t nat ${arg} OUTPUT -p ${proto} --dport ${outer} -j DNAT --to-destination ${ip}:${inner}"
  ];

  mkWgForwardRules = cmd: rules: concatMap
    (rule: concatMap (proto: mkWgForwardRule cmd rule.ip rule.outer rule.inner proto) rule.protos)
    (map (rule: rule // (if rule?inner then {} else { inner = rule.outer; })) rules)
  ;

  mkWgPeer = key: ip: { publicKey = key; allowedIPs = [ "${ip}/32" ]; };
in {
  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    # DO NOT REMOVE, needed for wireguard port forwarding
    net.ipv4.ip_forward = 1;
    # https://unix.stackexchange.com/a/112232
    net.ipv4.conf.all.route_localnet = 1;
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [ amneziawg ];
  boot.kernelModules = [ "amneziawg" ];

  networking.wireguard = {
    useNetworkd = false;
    interfaces.awg0 = let
      peers = [
        (mkWgPeer "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=" "10.200.200.2") # fa506ih
        (mkWgPeer "n0PDD0Ro8A34wG5yjoaC71JzyvrUksqd1AFYpyDyQl4=" "10.200.200.10") # qblue
        (mkWgPeer "TG4GGODEYH0JUunFv+kXcpYbNLihODXcgR7X3b3Tbgw=" "10.200.200.20") # mi9l
        (mkWgPeer "0ihUeP3zg9CmGjT4evfbcO1x2bnL7yHaytrttT1Mszs=" "10.200.200.3") # and pc
        (mkWgPeer "RvWdzzokCrVSL0fgvG/Exmp+2dYVmeSNKkhwmmT51z0=" "10.200.200.30") # and phone
        (mkWgPeer "KIRAECnHHExL8mpSgg2Ie9M9Bs78Wuctvz3hnK+bA28=" "10.200.200.197") # kir linux
        (mkWgPeer "KIRAwgVP50u4P2jqBisGSqoZ4nQpfaKJ5HyvmuvdQ10=" "10.200.200.198") # kir windows
        (mkWgPeer "kIRLBInjS/jHm11QMI55IEUV0wxewBwXgDnD6Uja0zk=" "10.200.200.199") # kir laptop
        (mkWgPeer "YAnDnt7Nebfdsdts2ugHZHUo2hmqL0pD//jpb9zwPmQ=" "10.200.200.41") # proxima
        (mkWgPeer "pLUtoUowRkkp4a00eimV7oBhUzq4JgHk9OIi5oP7wTA=" "10.200.200.50") # pluto
      ];
      rules = [
        { ip = "10.200.200.2"; outer = 8000; protos = [ "tcp" ]; } # python's http server
        #{ ip = "10.200.200.2"; outer = 16228; protos = [ "udp" ]; } # project zomboid
        { ip = "10.200.200.10"; outer = 4533; protos = [ "tcp" ]; } # navidrome on qboxblue
        { ip = "10.200.200.198"; outer = 50123; protos = [ "tcp" ]; } # kir's nonsense
        { ip = "10.200.200.198"; outer = 26639; protos = [ "tcp" ]; } # kir's comfy ui
      ];
    in {
      type = "amneziawg";
      ips = [ "10.200.200.1/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wireguard/private-key".path;
      peers = peers;
      postSetup = lib.concatLines ((wrapIptables [
        "-I FORWARD -i awg0 -j ACCEPT"
        "-I FORWARD -o awg0 -j ACCEPT"
        "-t nat -I POSTROUTING -s 10.200.200.0/24 -o ens3 -j MASQUERADE"
      ]) ++ (mkWgForwardRules "up" rules));
      preShutdown = lib.concatLines ((wrapIptables [
        "-D FORWARD -i awg0 -j ACCEPT"
        "-D FORWARD -o awg0 -j ACCEPT"
        "-t nat -D POSTROUTING -s 10.200.200.0/24 -o ens3 -j MASQUERADE"
      ]) ++ (mkWgForwardRules "down" rules));
      extraOptions = {
        Jc = 2;
        Jmin = 40;
        Jmax = 70;
        H1 = 1;
        H2 = 2;
        H3 = 3;
        H4 = 4;
      };
    };
  };

  # act as a dns resolver for wireguard network
  services.blocky.settings.ports.dns = [ "10.200.200.1:53" ];

  # DO NOT USE NIXOS' BUILTIN NAT AND PORT FORWARDING OPTIONS!!!
  # They do NOT work how I want. I spent 7 hours fighting it in the past.
  # Do not repeat this mistake, just don't bother with this shit,
  # you have iptables, they work, DO NOT FIX WHAT IS NOT BROKEN.
  #networking.nat = {
  #  enable = true;
  #  internalInterfaces = [ "awg0" ];
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
}

