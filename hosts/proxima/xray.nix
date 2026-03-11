{ config, ... }:

let
  ph = config.sops.placeholder;

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
        "clients": ${ph."xray/vless-in/settings/clients"},
        "decryption": "none"
       },
       "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
         "dest": "${ph."xray/vless-in/streamSettings/realitySettings/dest"}:443",
         "serverNames": [ "${ph."xray/vless-in/streamSettings/realitySettings/dest"}" ],
         "privateKey": "${ph."xray/vless-in/streamSettings/realitySettings/privateKey"}",
         "shortIds": ${ph."xray/vless-in/streamSettings/realitySettings/shortIds"}
        },
        "xhttpSettings": {
         "path": "${ph."xray/vless-in/streamSettings/xhttpSettings/path"}"
        }
       },
       "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls", "quic" ],
        "routeOnly": true
       }
      },
      {
       "tag": "wireguard-in",
       "protocol": "dokodemo-door",
       "listen": "127.0.0.1",
       "port": 51821,
       "settings": {
        "address": "127.0.0.1",
        "port": 51820,
        "network": "udp"
       }
      }
     ],
     "outbounds": [
      {
       "tag": "vless-out",
       "protocol": "vless",
       "settings": {
        "address": "${ph."xray/vless-out/settings/address"}",
        "port": 443,
        "id": "${ph."xray/vless-out/settings/id"}",
        "encryption": "none"
       },
       "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
         "serverName": "${ph."xray/vless-out/streamSettings/realitySettings/serverName"}",
         "publicKey": "${ph."xray/vless-out/streamSettings/realitySettings/publicKey"}",
         "shortId": "${ph."xray/vless-out/streamSettings/realitySettings/shortId"}"
        },
        "xhttpSettings": {
         "path": "${ph."xray/vless-out/streamSettings/xhttpSettings/path"}"
        }
       }
      },
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
        "domain": [ "geosite:category-ru", "domain:chutes.ai", "domain:openrouter.ai" ],
        "outboundTag": "direct-out"
       },
       {
        "ip": [ "geoip:ru" ],
        "outboundTag": "direct-out"
       },
       {
        "port": "53",
        "outboundTag": "dns-out"
       },
       {
        "inboundTag": [ "wireguard-in" ],
        "outboundTag": "vless-out"
       },
       {
        "protocol": [ "bittorrent" ],
        "outboundTag": "block"
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

