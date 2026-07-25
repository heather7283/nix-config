{ config, pkgs, lib, ... }:

let
  uid = 992; # prayge that it's not alredy taken (cuxos doesn't guard against this)
in {
  users = {
    users.omniroute = {
      inherit uid;
      group = "omniroute";
    };
    groups.omniroute = {
      gid = uid;
    };
  };

  systemd.tmpfiles.settings.omniroute."/var/lib/omniroute"."d" = {
    user = "omniroute";
    group = "omniroute";
    mode = "0700";
  };

  virtualisation.oci-containers.containers.omniroute = {
    serviceName = "omniroute";
    user = with config.users; "${toString users.omniroute.uid}:${toString groups.omniroute.gid}";
    image = "diegosouzapw/omniroute:latest";
    volumes = [ "/var/lib/omniroute:/app/data" ];
    ports = [ "127.0.0.1:20128:20128" ];
    extraOptions = [ "--network=host" ]; # idk how else I can make it see the proxy

    environment = {
      ENABLE_SOCKS5_PROXY = "true";
      NEXT_PUBLIC_ENABLE_SOCKS5_PROXY = "true";
      ALL_PROXY = "socks5://127.0.0.1:10808"; # xray socks inbound that will send it through warp
      PROXY_FAIL_OPEN = "false";
      #ENABLE_TLS_FINGERPRINT = "true"; # Couldn't get it to work with proxy for whatever reason
    };
  };
  systemd.services.omniroute = rec {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" "dante-omniroute.service" ];
    after = wants;
  };
}

