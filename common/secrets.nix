{ config, lib, pkgs, secrets, hostname, ... }:

{
  sops = {
    gnupg.sshKeyPaths = lib.mkDefault [];
    age.sshKeyPaths = lib.mkDefault [];

    age = {
      keyFile = lib.mkDefault "/nix/config/keys.txt";
      generateKey = lib.mkDefault false;
    };

    defaultSopsFile = secrets.paths."${hostname}"."secrets.yaml";
    defaultSopsFormat = "yaml";
  };
}

