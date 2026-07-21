{ config, pkgs, lib, ... }:

{
  users = let
    id = 992; # prayge that it's not alredy taken (cuxos doesn't guard against this)
  in {
    users.omniroute = {
      uid = id;
      group = "omniroute";
    };
    groups.omniroute = {
      gid = id;
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
    #environment = {
    #  ENABLE_SOCKS5_PROXY = "true";
    #  ALL_PROXY = "TODO";
    #  ENABLE_TLS_FINGERPRINT = "true";
    #};
  };
}

