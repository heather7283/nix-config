{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = let
    paths = secrets.paths."${hostname}";
    files = {
      users.heather.password = _: { neededForUsers = true; };

      wireguard.private-key = _: {};

      xray = {
        vless-in = {
          settings = {
            clients = _: {};
            decryption = _: {};
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

      ddns = {
        noip = {
          domain = _: {};
          username = _: {};
          password = _: {};
        };
      };
    };
  in {
    secrets = builtins.mapAttrs
      (k: v: v <| lib.ext.split "/" k)
      (lib.ext.flattenAttrs "/" files)
    ;
  };
}

