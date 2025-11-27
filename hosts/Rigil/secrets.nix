{ config, lib, pkgs, nix-secrets, ... }:

{
  sops = let paths = nix-secrets.paths.rigil; in {
    defaultSopsFile = paths."secrets.yaml";
    defaultSopsFormat = "yaml";
    age = {
      sshKeyPaths = lib.mkForce []; # not needed in my config
      keyFile = "/nix/config/keys.txt";
      generateKey = false;
    };
    secrets = {
      "ip" = {};
      "xray-config.jsonc" = {
        sopsFile = paths."xray-config.jsonc";
        format = "binary";
      };
      "jmusicbot-config.txt" = {
        sopsFile = paths."jmusicbot-config.txt";
        format = "binary";
      };
      "wg-quick-wg0.conf" = {
        sopsFile = paths."wg-quick-wg0.conf";
        format = "binary";
      };
    };
  };
}

