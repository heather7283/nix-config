{ config, lib, pkgs, ... }:

{
  sops = {
    gnupg.sshKeyPaths = lib.mkDefault [];
    age.sshKeyPaths = lib.mkDefault [];

    age = {
      keyFile = lib.mkDefault "/nix/config/keys.txt";
      generateKey = lib.mkDefault false;
    };
  };
}

