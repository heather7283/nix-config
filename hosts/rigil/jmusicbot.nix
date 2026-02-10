{ config, ... }:

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
    '';
    restartUnits = [ "jmusicbot.service" ];
  };

  services.jmusicbot = {
    enable = true;
    configFile = config.sops.templates."jmusicbot_config.txt".path;
  };
}

