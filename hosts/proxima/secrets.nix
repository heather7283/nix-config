{ config, lib, pkgs, secrets, ... }:

{
  sops = let
    paths = secrets.paths.proxima;
  in {
    defaultSopsFile = paths."secrets.yaml";
    defaultSopsFormat = "yaml";

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

