{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = let
    paths = secrets.paths."${hostname}";
  in {
    secrets = builtins.mapAttrs (k: v: lib.ext.split "/" k |> last |> v) (lib.ext.flattenAttrs "/" {
      users.heather.password = _: { neededForUsers = true; };

      wireguard.private-key = _: {};

      "xray-config.jsonc" = f: {
        sopsFile = paths."${f}";
        format = "binary";
        restartUnits = [ "xray.service" ];
      };
    });
  };
}

