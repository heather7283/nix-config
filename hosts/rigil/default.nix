{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  users.users.heather.hashedPasswordFile = config.sops.secrets."users/heather/password".path;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = false;

  ext.zram.enable = true;

  services.giorno = {
    enable = false;
    configFile = config.sops.secrets."giorno/config.toml".path;
    tokenFile = config.sops.secrets."giorno/token.txt".path;
  };

  services.ycurator = {
    enable = true;
    keyFile = config.sops.secrets."ycurator/authorized_key.json".path;
    configFile = config.sops.secrets."ycurator/config.json".path;
  };

  virtualisation.quadlet = {
    enable = true;
    autoUpdate = {
      enable = true;
      startAt = "*-*-* 08:00:00 Europe/Samara";
    };
  };
}

