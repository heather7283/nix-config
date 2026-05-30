{ config, lib, pkgs, ... }:

let
  if6 = yes: no: if config.networking.enableIPv6 then yes else no;
in {
  services.blocky = {
    enable = true;
    settings = let
      nameservers = [
        {
          upstream = "https://one.one.one.one/dns-query";
          ips = [ "1.1.1.1" "1.0.0.1" ] ++ if6 [ "2606:4700:4700::1111" "2606:4700:4700::1001" ] [];
        }
        {
          upstream = "https://dns.google/dns-query";
          ips = [ "8.8.8.8" "8.8.4.4" ] ++ if6 [ "2001:4860:4860::8888" "2001:4860:4860::8844" ] [];
        }
        {
          upstream = "https://dns.quad9.net/dns-query";
          ips = [ "9.9.9.9" "149.112.112.112" ] ++ if6 [ "2620:fe::9" "2620:fe::fe" ] [];
        }
      ];
    in with builtins; {
      upstreams.groups.default = nameservers |> map (ns: ns.upstream);
      bootstrapDns = nameservers;

      ports.dns = [ "127.0.0.1:53" ] ++ if6 [ "[::1]:53" ] [];

      hostsFile.sources = [ "/etc/hosts" ];

      log = {
        level = "warn";
        timestamp = false;
      };
    } // if6 {} {
      connectIPVersion = "v4";
      filtering.queryTypes = [ "AAAA" ];
    };
  };

  # see https://discourse.nixos.org/t/why-cant-i-get-dns-nameservers-to-stick/59132
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    ${if6 "nameserver ::1" ""}
  '';
}

