{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = let
    paths = secrets.paths."${hostname}";
    files = {
      users.heather.password = _: { neededForUsers = true; };

      wireguard.private-key = _: {};

      "xray-config.jsonc" = p: {
        sopsFile = lib.getAttrFromPath p paths;
        format = "binary";
        restartUnits = [ "xray.service" ];
      };
    };
  in {
    secrets = builtins.mapAttrs
      (k: v: v <| lib.ext.split "/" k)
      (lib.ext.flattenAttrs "/" files)
    ;
  };
}

