{ config, lib, pkgs, secrets, ... }:

{
  sops = let
    paths = secrets.paths.rigil;
  in {
    defaultSopsFile = paths."secrets.yaml";
    defaultSopsFormat = "yaml";
    age = {
      sshKeyPaths = lib.mkForce []; # not needed in my config
      keyFile = "/nix/config/keys.txt";
      generateKey = false;
    };
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
    };
  };
}

