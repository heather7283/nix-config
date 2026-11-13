{ config, pkgs, lib, ... }:

let
  name = "muse";
  uid = 987;
in {
  users = {
    users."${name}" = {
      uid = uid;
      group = name;
      isSystemUser = true;
    };
    groups."${name}" = {
      gid = uid;
    };
  };

  systemd.tmpfiles.settings."${name}"."/var/lib/${name}".d = {
    mode = "0700";
    user = name;
    group = name;
  };

  sops.templates."${name}.env" = let
    ph = config.sops.placeholder;
  in {
    content = ''
      DISCORD_TOKEN=${ph."muse/discord_token"}
      YOUTUBE_API_KEY=${ph."muse/youtube_api_key"}
    '';
  };

  virtualisation.quadlet.containers."${name}" = {
    containerConfig = {
      HostName = name;
      Image = "ghcr.io/museofficial/muse:yt-dlp-latest";
      AutoUpdate = "registry";

      User = toString config.users.users."${name}".uid;
      Group = toString config.users.groups."${name}".gid;
      Volume = [
        "/var/lib/muse:/data"
      ];

      EnvironmentFile = config.sops.templates."${name}.env".path;
    };
    unitConfig = rec {
      Wants = [ "network-online.target" ];
      After = Wants;
    };
  };
}

