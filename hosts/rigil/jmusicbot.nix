{ config, pkgs, ... }:

{
  # see https://jmusicbot.com/config/
  sops.templates."jmusicbot_config.txt" = {
    content = ''
      token = ${config.sops.placeholder."jmusicbot/token"}
      owner = ${config.sops.placeholder."jmusicbot/owner"}

      altprefix = "!"

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

  virtualisation.oci-containers.containers.jmusicbot = {
    serviceName = "jmusicbot";
    image = "eclipse-temurin:25-jdk";
    volumes = let
      v = "0.11.0";
      jar = pkgs.fetchurl {
        url =
          "https://github.com/Cosgy-Dev/JMusicBot-JP/releases/download/${v}/JMusicBot-${v}-All.jar";
        sha256 = "sha256-cVlugGrTLGO7YdaT8Ywx2kaNqcKEPUMR/yjF6HetyMk=";
      };
      cfg = config.sops.templates."jmusicbot_config.txt".path;
    in [
      "${jar}:/jmusicbot.jar:ro"
      "${cfg}:/config.txt:ro"
    ];
    workdir = "/";
    entrypoint = "java";
    cmd = [
      "--enable-native-access=ALL-UNNAMED"
      "-Dnogui=true"
      "-Dconfig.file=/config.txt"
      "-jar" "/jmusicbot.jar"
    ];
  };
}

