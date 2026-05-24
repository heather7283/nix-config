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

  # Backup in case duckdns is down (has happened before)
  systemd.timers.noip-updater = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "0 sec";
      OnUnitActiveSec = "5 min";
    };
  };
  systemd.services.noip-updater = let
    script = with pkgs; writeShellApplication {
      name = "noip-updater";
      runtimeInputs = [ curl ];
      text = ''
        ip="$(curl -sS ifconfig.me/ip)"
        hostname="$(cat "$CREDENTIALS_DIRECTORY/hostname")"
        username="$(cat "$CREDENTIALS_DIRECTORY/username")"
        password="$(cat "$CREDENTIALS_DIRECTORY/password")"

        curl -sS \
          -H "Authorization: Basic $(echo "$username:$password" | base64)" \
          "https://dynupdate.no-ip.com/nic/update?hostname=$hostname&myip=$ip"
      '';
    };
  in {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${script}/bin/noip-updater";
      LoadCredential = [
        "hostname:${config.sops.secrets."ddns/noip/hostname".path}"
        "username:${config.sops.secrets."ddns/noip/username".path}"
        "password:${config.sops.secrets."ddns/noip/password".path}"
      ];
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}

