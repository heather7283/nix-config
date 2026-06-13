{ pkgs, lib, config, ... }:

{
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
        domain="$(cat "$CREDENTIALS_DIRECTORY/domain")"
        token="$(cat "$CREDENTIALS_DIRECTORY/token")"
        exec curl -fsS "https://www.duckdns.org/update?domains=$domain&token=$token"
      '';
    };
  in {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe script;
      LoadCredential = [
        "domain:${config.sops.secrets."ddns/duckdns/domain".path}"
        "token:${config.sops.secrets."ddns/duckdns/token".path}"
      ];
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}

