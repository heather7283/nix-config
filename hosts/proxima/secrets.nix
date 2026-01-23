{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = let
    paths = secrets.paths."${hostname}";
  in {
    secrets = {
      "users/heather/password" = {
        neededForUsers = true;
      };
      "wireguard/private-key" = {};
      "xray-config.jsonc" = {
        sopsFile = paths."xray-config.jsonc";
        format = "binary";
        restartUnits = [ "xray.service" ];
      };
    };
  };
}

