{ config, pkgs, ... }:

let
  ph = config.sops.placeholder;

  xrayConfig = ''
    {
     "log": {
      "loglevel": "debug",
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
        "clients": ${ph."xray/vless-in/settings/clients"},
        "decryption": "${ph."xray/vless-in/settings/decryption"}"
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
      //{
      // "tag": "turn-proxy-in",
      // "protocol": "wireguard",
      // "listen": "127.0.0.1",
      // "port": 56001,
      // "settings": {
      // }
      //},
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
       "tag": "block",
       "protocol": "blackhole"
      },
      {
       "tag": "direct-out",
       "protocol": "freedom"
      },
      {
       "tag": "dns-out",
       "protocol": "freedom",
       "settings": {
        "redirect": "127.0.0.1:53"
       }
      }
     ],
     "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
       {
        "ruleTag": "api",
        "inboundTag": [ "api-in" ],
        "outboundTag": "api-out"
       },
       {
        "ruleTag": "wireguard",
        "inboundTag": [ "vless-in" ],
        "ip": [ "127.0.0.1" ],
        "port": 51820,
        "outboundTag": "direct-out"
       },
       {
        "ruleTag": "block-private-ips",
        "ip": [ "geoip:private" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "hijack-dns",
        "inboundTag": [ "vless-in" ],
        "port": "53",
        "outboundTag": "dns-out"
       },
       {
        "ruleTag": "forward-to-pluto",
        "inboundTag": [ "vless-in" ],
        "outboundTag": "pluto-out"
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
    package = pkgs.unstable.xray;
  };
  systemd.services.xray.serviceConfig.LogsDirectory = "xray";

  services.logrotate.settings."/var/log/xray/*.log" = {
    frequency = "daily";
    copytruncate = true;
  };

  services.prometheus.exporters.v2ray = {
    enable = true;
    listenAddress = "10.200.200.41";
    port = 9092;
    v2rayEndpoint = "127.0.0.1:54321";
  };
  systemd.services.prometheus-v2ray-exporter.bindsTo = [ "wireguard-wg0.target" ];
  systemd.services.prometheus-v2ray-exporter.after = [ "wireguard-wg0.target" ];

  services.turn-proxy.server = {
    enable = true; # Включаем шарманку
    config = {
      listeningOn = "0.0.0.0:56000"; # Адрес, который слушает программа, то есть куда будет обращаться TURN сервер с зашифрованным (с помощью DTLS) трафиком (адресант)
      proxyInto = "127.0.0.1:56001"; # Адрес, куда будет высылаться расшифрованный UDP-трафик (адресат)
      maxConnections = 2000;
    };
  };
}

