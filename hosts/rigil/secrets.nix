{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = let
    paths = secrets.paths."${hostname}";
  in {
    secrets = builtins.mapAttrs (k: v: v <| lib.ext.split "/" k) (lib.ext.flattenAttrs "/" {
      ip = {
        v4 = {
          address = _: {};
          gateway = _: {};
        };
        v6 = {
          address = _: {};
          gateway = _: {};
        };
      };

      users.heather.password = _: { neededForUsers = true; };

      grafana = {
        admin_password = _: {};
        secret_key = _: {};
      };

      wireguard.private-key = _: {};

      jmusicbot = {
        token = _: { restartUnits = [ "jmusicbot.service" ]; };
        owner = _: { restartUnits = [ "jmusicbot.service" ]; };
      };

      bitcoind.rpcauth = _: {};

      xray = {
        vless-in = {
          settings = {
            clients = _: {};
          };
          streamSettings = {
            realitySettings = {
              dest = _: {};
              privateKey = _: {};
              shortIds = _: {};
            };
            xhttpSettings = {
              path = _: {};
            };
          };
        };
      };

      giorno = {
        "config.toml" = _: {
          sopsFile = paths.giorno."config.toml";
          format = "binary";
          restartUnits = [ "giorno.service" ];
        };
        "token.txt" = _: {
          sopsFile = paths.giorno."token.txt";
          format = "binary";
          restartUnits = [ "giorno.service" ];
        };
      };

      ycurator = {
        "config.json" = p: {
          sopsFile = lib.getAttrFromPath p paths;
          format = "json";
          key = "";
          restartUnits = [ "ycurator.service" ];
        };
        "authorized_key.json" = p: {
          sopsFile = lib.getAttrFromPath p paths;
          format = "json";
          key = "";
          restartUnits = [ "ycurator.service" ];
        };
      };

      warp = {
        "reg.json" = path: {
          sopsFile = lib.getAttrFromPath path paths;
          format = "json";
          key = "";
          restartUnits = [ "cf-warp.service" ];
        };
      };

      harmonia.signKey = _: {};
    });
  };
}

