{ config, ... }:

{
  # see https://jmusicbot.com/config/
  sops.templates."jmusicbot_config.txt".content = ''
    token = ${config.sops.placeholder."jmusicbot/token"}
    owner = ${config.sops.placeholder."jmusicbot/owner"}
  '';

  services.jmusicbot = {
    enable = true;
    configFile = config.sops.templates."jmusicbot_config.txt".path;
  };
}

