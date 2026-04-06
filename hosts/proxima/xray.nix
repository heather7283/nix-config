{ config, pkgs, ... }:

let
  ph = config.sops.placeholder;

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
       "protocol": "freedom",
       "settings": {
        "redirect": "127.0.0.1:53"
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
        "ruleTag": "api",
        "inboundTag": [ "api-in" ],
        "outboundTag": "api-out"
       },
       {
        "ruleTag": "wireguard",
        "inboundTag": [ "wireguard-in" ],
        "outboundTag": "vless-out"
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
        "vlessRoute": 1,
        "outboundTag": "pluto-out"
       },
       {
        "ruleTag": "russian-domains",
        "inboundTag": [ "vless-in" ],
        "domain": [ "geosite:category-ru", "domain:chutes.ai", "domain:openrouter.ai" ],
        "outboundTag": "direct-out"
       },
       {
        "ruleTag": "russian-ips",
        "inboundTag": [ "vless-in" ],
        "ip": [ "geoip:ru" ],
        "outboundTag": "direct-out"
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
  systemd.services.prometheus-v2ray-exporter.requires = [ "sys-devices-virtual-net-wg0.device" ];
}

