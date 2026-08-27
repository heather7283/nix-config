{ config, pkgs, lib, ... }:

{
  # see https://jmusicbot.com/config/
  sops.templates."jmusicbot_config.txt" = {
    content = ''
      token = ${config.sops.placeholder."jmusicbot/token"}
      owner = ${config.sops.placeholder."jmusicbot/owner"}

      altprefix = "!"
      helptodm = false

      aliases {
        nowplaying = [ np ]
        play = [ p ]
        remove = [ delete ]
      }

      stayinchannel = true
      alonetimeuntilstop = 300
    '';
    restartUnits = [ "jmusicbot.service" ];
  };

  virtualisation.quadlet.containers.jmusicbot = {
    containerConfig = {
      Image = "docker.io/library/eclipse-temurin:25-jre";
      Volume = let
        jar = pkgs.ext.fetchGitHubRelease rec {
          owner = "Cosgy-Dev";
          repo = "JMusicBot-JP";
          tag = "0.11.0";
          asset = "JMusicBot-${tag}-All.jar";
          sha256 = "sha256-cVlugGrTLGO7YdaT8Ywx2kaNqcKEPUMR/yjF6HetyMk=";
        };
        cfg = config.sops.templates."jmusicbot_config.txt".path;
      in [
        "${jar}:/jmusicbot.jar:ro"
        "${cfg}:/config.txt:ro"
      ];
      WorkingDir = "/";
      Entrypoint = "java";
      Exec = builtins.concatStringsSep " " [
        "--enable-native-access=ALL-UNNAMED"
        "-Dnogui=true"
        "-Dconfig.file=/config.txt"
        "-jar" "/jmusicbot.jar"
      ];
      NoNewPrivileges = true;
    };
    unitConfig = rec {
      Wants = [ "network-online.target" ];
      After = Wants;
    };
  };
}

