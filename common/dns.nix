{ config, lib, pkgs, ... }:

{
  services.blocky = {
    enable = true;
    settings = let
      nameservers = [
        [ "https://one.one.one.one/dns-query" "1.1.1.1" "1.0.0.1" ]
        [ "https://dns.google/dns-query" "8.8.8.8" "8.8.4.4" ]
        [ "https://dns.quad9.net/dns-query" "9.9.9.9" "149.112.112.112" ]
      ];
      hasIPv6 = config.networking.enableIPv6;
    in with builtins; {
      upstreams.groups.default = map (a: head a) nameservers;
      bootstrapDns = map (a: { upstream = head a; ips = tail a; }) nameservers;

      ports.dns = [ "127.0.0.1:53" ] ++ (if hasIPv6 then [ "[::1]:53" ] else []);

      hostsFile.sources = [ "/etc/hosts" ];

      log = {
        level = "warn";
        timestamp = false;
      };
    } // (if hasIPv6 then {} else {
      connectIPVersion = "v4";
      filtering.queryTypes = [ "AAAA" ];
    });
  };

  # see https://discourse.nixos.org/t/why-cant-i-get-dns-nameservers-to-stick/59132
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
  '';
}

