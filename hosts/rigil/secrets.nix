{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = let
    paths = secrets.paths."${hostname}";
  in {
    secrets = {
      "ip" = {};
      "users/heather/password" = {
        neededForUsers = true;
      };
      "wireguard/private-key" = {};

      "xray-config.jsonc" = {
        sopsFile = paths."xray-config.jsonc";
        format = "binary";
        restartUnits = [ "xray.service" ];
      };

      "jmusicbot-config.txt" = {
        sopsFile = paths."jmusicbot-config.txt";
        format = "binary";
        restartUnits = [ "jmusicbot.service" ];
      };

      "giorno/config.toml" = {
        sopsFile = paths.giorno."config.toml";
        format = "binary";
        restartUnits = [ "giorno.service" ];
      };
      "giorno/token.txt" = {
        sopsFile = paths.giorno."token.txt";
        format = "binary";
        restartUnits = [ "giorno.service" ];
      };

      "ycurator/authorized_key.json" = {
        sopsFile = paths.ycurator."authorized_key.json";
        key = "";
        format = "json";
        restartUnits = [ "ycurator.service" ];
      };
      "ycurator/config.json" = {
        sopsFile = paths.ycurator."config.json";
        key = "";
        format = "json";
        restartUnits = [ "ycurator.service" ];
      };
    };
  };
}

