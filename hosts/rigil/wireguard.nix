{ config, lib, pkgs, ... }:

with builtins; let
  # TODO: rewrite all of this to work with nftables
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
in {
  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    # DO NOT REMOVE, needed for wireguard port forwarding
    net.ipv4.ip_forward = 1;
    # https://unix.stackexchange.com/a/112232
    net.ipv4.conf.all.route_localnet = 1;
  };

  networking.wireguard = {
    useNetworkd = false;
    interfaces.wg0 = let
      peers = [
        {
          # fa506ih
          publicKey = "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=";
          allowedIPs = [ "10.200.200.2/32" ];
        }
      ];
    in {
      ips = [ "10.200.200.3/32" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wireguard/private-key".path;
      peers = peers;
    };
  };

  # DO NOT USE NIXOS' BUILTIN NAT AND PORT FORWARDING OPTIONS!!!
  # They do NOT work how I want. I spent 7 hours fighting it in the past.
  # Do not repeat this mistake, just don't bother with this shit,
  # you have iptables, they work, DO NOT FIX WHAT IS NOT BROKEN.
  #networking.nat = {
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
}

