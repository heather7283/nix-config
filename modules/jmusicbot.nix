{ lib, pkgs, config, ... }:

let
  cfg = config.services.jmusicbot;
in {
  # upstream module is cringe
  disabledModules = [ "services/audio/jmusicbot.nix" ];

  options.services.jmusicbot = {
    enable = lib.mkEnableOption "Run JMusicBot (Discord music bot) as a service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fetchurl {
        url = "https://github.com/SeVile/MusicBot/releases/download/0.4.4.0/JMusicBot-0.4.4.0.jar";
        sha256 = "sha256-lkpWJUcBYY7RaAWOgrUVpNyaMwh8qPTYi9IpqnQUbTA=";
      };
      description = "The JMusicBot JAR";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = "Path to a JMusicBot configuration file";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jmusicbot = {
      description = "JMusicBot Discord Music Bot";

      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = true;
        LoadCredential = "config.txt:${cfg.configFile}";
        StateDirectory = "jmusicbot";
        WorkingDirectory = "/var/lib/jmusicbot";

        ExecStart = builtins.concatStringsSep " " [
          "${pkgs.jre}/bin/java"
          "-Dconfig.file=\"\${CREDENTIALS_DIRECTORY}/config.txt\""
          "-Dnogui=true"
          "-jar ${cfg.package}"
        ];
      };
    };
  };
}

