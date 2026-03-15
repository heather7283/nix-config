{ config, pkgs, lib, ... }:

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
     "api": {
      "tag": "api-out",
      "services": [ "StatsService" ]
     },
     "stats": {
     },
     "policy": {
      "levels": {
       "0": {
        "statsUserUplink": true,
        "statsUserDownlink": true
       }
      },
      "system": {
       "statsInboundUplink": true,
       "statsInboundDownlink": true,
       "statsOutboundUplink": true,
       "statsOutboundDownlink": true
      }
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
      },
      {
       "tag": "api-in",
       "protocol": "dokodemo-door",
       "listen": "127.0.0.1",
       "port": 54321,
       "settings": { "address": "127.0.0.1" }
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
       },
       {
        "ruleTag": "prevent-return-to-russia-ip",
        "ip": [ "geoip:ru" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "prevent-return-to-russia-domain",
        "domain": [ "geosite:category-ru" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "block-bittorrent",
        "protocol": [ "bittorrent" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "api",
        "inboundTag": [ "api-in" ],
        "outboundTag": "api-out"
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
    # stable nixos has ancient geoip/domain list and I have no idea how to overwrite only those
    package = pkgs.unstable.xray;
  };
  systemd.services.xray = {
    # make sure /var/log/xray exists
    serviceConfig.LogsDirectory = "xray";
  };

  # I once had xray logs grow to 1 gig so yeah better set this up
  services.logrotate.settings."/var/log/xray/*.log" = {
    frequency = "daily";
    copytruncate = true;
  };

  services.prometheus.exporters.v2ray = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9092;
    v2rayEndpoint = "127.0.0.1:54321";
  };
}

