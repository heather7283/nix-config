{ config, ... }:

let
  ph = config.sops.placeholder;

  clients = ph."xray/vless-in/settings/clients";
  dest = ph."xray/vless-in/streamSettings/realitySettings/dest";
  privateKey = ph."xray/vless-in/streamSettings/realitySettings/privateKey";
  shortIds = ph."xray/vless-in/streamSettings/realitySettings/shortIds";
  path = ph."xray/vless-in/streamSettings/xhttpSettings/path";

  xrayConfig = ''
    {
     "log": {
      "loglevel": "error",
      "access": "/var/log/xray/access.log",
      "error": "/var/log/xray/error.log"
     },
     "inbounds": [
      {
       "tag": "vless-in",
       "protocol": "vless",
       "listen": "0.0.0.0",
       "port": 443,
       "settings": {
        "clients": ${clients},
        "decryption": "none"
       },
       "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
         "dest": "${dest}:443",
         "serverNames": [ "${dest}" ],
         "privateKey": "${privateKey}",
         "shortIds": ${shortIds}
        },
        "xhttpSettings": {
         "path": "${path}"
        }
       },
       "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls", "quic" ],
        "routeOnly": true
       }
      }
     ],
     "outbounds": [
      {
       "tag": "direct-out",
       "protocol": "freedom"
      },
      {
       "tag": "dns-out",
       "protocol": "dns",
       "settings": {
        "nonIPQuery": "drop"
       }
      },
      {
       "tag": "block",
       "protocol": "blackhole"
      }
     ],
     "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
       {
        "ruleTag": "vless-in-force-redirect-dns",
        "inboundTag": [ "vless-in" ],
        "port": 53,
        "outboundTag": "dns-out"
       }
      ]
     }
    }
  '';
in {
  sops.templates."xray-config.jsonc" = {
    content = xrayConfig;
    restartUnits = [ "xray.service" ];
  };

  services.xray = {
    enable = true;
    settingsFile = config.sops.templates."xray-config.jsonc".path;
  };
  systemd.services.xray.serviceConfig.LogsDirectory = "xray";
}

