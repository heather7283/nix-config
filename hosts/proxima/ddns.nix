{ pkgs, lib, config, ... }:

{
  # I couldn't get ddns-updater to work so this will do
  systemd.timers.duckdns-updater = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "0 sec";
      OnUnitActiveSec = "5 min";
    };
  };
  systemd.services.duckdns-updater = let
    script = with pkgs; writeShellApplication {
      name = "duckdns-updater";
      runtimeInputs = [ curl ];
      text = ''
        ip="$(curl -sS ifconfig.me/ip)"
        domain="$(cat "$CREDENTIALS_DIRECTORY/domain")"
        token="$(cat "$CREDENTIALS_DIRECTORY/token")"

        curl -sS "https://www.duckdns.org/update?domains=$domain&token=$token&ip=$ip"
      '';
    };
  in {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${script}/bin/duckdns-updater";
      LoadCredential = [
        "domain:${config.sops.secrets."ddns/duckdns/domain".path}"
        "token:${config.sops.secrets."ddns/duckdns/token".path}"
      ];
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  services.ext.server-identification.enable = true;
}

