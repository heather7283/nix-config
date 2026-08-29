{ pkgs, lib, config, ... }:

{
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.sops.secrets."harmonia/signKey".path ];
  };
}

