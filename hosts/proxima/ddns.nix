{ pkgs, lib, config, ... }:

{
  sops.templates."ddns-updater-config.json" = {
    content = ''
      {
        "settings": [
          {
            "provider": "noip",
            "domain": "${config.sops.placeholder."ddns/noip/domain"}",
            "username": "${config.sops.placeholder."ddns/noip/username"}",
            "password": "${config.sops.placeholder."ddns/noip/password"}",
            "ip_version": "ipv4"
          }
        ]
      }
    '';
  };

  services.ddns-updater = {
    enable = true;
    environment = {
      SERVER_ENABLED = "no";
      PERIOD = "5m";
      CONFIG_FILEPATH = "%d/config.json";
    };
  };

  systemd.services.ddns-updater = {
    serviceConfig.LoadCredential = [
      "config.json:${config.sops.templates."ddns-updater-config.json".path}"
    ];
  };
}

