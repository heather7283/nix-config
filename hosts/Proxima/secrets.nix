{ config, lib, pkgs, nix-secrets, ... }:

{
  sops = let paths = nix-secrets.paths.proxima; in {
    defaultSopsFile = paths."secrets.yaml";
    defaultSopsFormat = "yaml";
    age = {
      sshKeyPaths = lib.mkForce []; # not needed in my config
      keyFile = "/etc/nixos/config/keys.txt";
      generateKey = false;
    };
    secrets = {
      "wireguard/private-key" = {};
      "xray-config.json" = {
        sopsFile = paths."xray-config.json";
        format = "json";
        key = "";
      };
    };
  };
}

