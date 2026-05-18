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
      "loglevel": "info",
      "access": "/var/log/xray/access.log",
      "error": "/var/log/xray/error.log"
     },
     "api": {
      "tag": "api",
      "listen": "127.0.0.1:54321",
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
      }
     ],
     "outbounds": [
      {
       "tag": "direct-out",
       "protocol": "freedom",
       "settings": {
        "finalRules": [
         { // wireguard
          "action": "allow",
          "network": "udp",
          "ip": [ "127.0.0.1" ],
          "port": 51820
         },
         { // fa506ih ssh (only really needed for pyxis)
          "action": "allow",
          "network": "tcp",
          "ip": [ "10.200.200.2" ],
          "port": 22
         },
         {
          "action": "block",
          "ip": [ "geoip:ru" ]
         }
         // implicit catch-all is to block private ranges
        ]
       }
      },
      {
       "tag": "warp-out",
       "protocol": "socks",
       "settings": {
        "address": "127.0.0.1",
        "port": 10809
       }
      },
      {
       "tag": "dns-out",
       "protocol": "dns",
       "settings": {
        "rewriteNetwork": "udp",
        "rewriteAddress": "127.0.0.1",
        "rewritePort": 53,
        "rules": [{ "action": "direct" }]
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
        "ruleTag": "wireguard",
        "inboundTag": [ "vless-in" ],
        "ip": [ "127.0.0.1" ],
        "port": 51820,
        "network": "udp",
        "outboundTag": "direct-out"
       },
       {
        "ruleTag": "pysix-wireguard-hack",
        "inboundTag": [ "vless-in" ],
        "ip": [ "10.200.200.0/24" ],
        "user": [ "pyxis@localhost" ],
        "outboundTag": "direct-out"
       },
       {
        "ruleTag": "block-private-ips",
        "ip": [ "geoip:private" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "block-bittorrent",
        "protocol": [ "bittorrent" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "hijack-dns",
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
        "ruleTag": "vless-route-0001-warp",
        "vlessRoute": 1,
        "outboundTag": "warp-out"
       },
       {
        // reddit seems to have blocked my IP lmao
        "ruleTag": "reddit-warp",
        "domain": [ "geosite:reddit" ],
        "outboundTag": "warp-out"
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
    compress = true;
  };

  services.prometheus.exporters.v2ray = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9092;
    v2rayEndpoint = "127.0.0.1:54321";
  };
}

