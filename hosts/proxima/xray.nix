{ config, pkgs, lib, ... }:

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
       "tag": "turn-proxy-in",
       "protocol": "vless",
       "listen": "127.0.0.1",
       "port": 56001,
       "settings": {
        "clients": ${ph."xray/turn-proxy-in/settings/clients"},
        "decryption": "none"
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
       "tag": "block",
       "protocol": "blackhole"
      },
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
         }
         // implicit catch-all is to block private ranges
        ]
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
        "ruleTag": "block-private-ips",
        "ip": [ "geoip:private" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "block-ads",
        "domain": [ "geosite:category-ads-all" ],
        "outboundTag": "block"
       },
       {
        "ruleTag": "hijack-dns",
        "port": "53",
        "outboundTag": "dns-out"
       },
       {
        "ruleTag": "forward-to-pluto",
        "inboundTag": [ "vless-in", "turn-proxy-in" ],
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

  systemd.services.vk-turn-proxy-server = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";

      ExecStart = let
        binary = pkgs.ext.fetchGitHubRelease {
          owner = "Moroka8";
          repo = "vk-turn-proxy";
          tag = "v1.10.0";
          asset = "server-linux-amd64";
          sha256 = "sha256-7Sd7Mgxcv82AhDH97DL9tknc1DliCH/pEb7K7CkBdUw=";
        };
      in pkgs.writeShellScript "vk-turn-proxy-start.sh" ''
        # do not set -x or the key will leak into journal lmao
        set -eu

        exec ${pkgs.ext.makeExecutable binary} \
          -connect 127.0.0.1:56001 -listen 0.0.0.0:56395 \
          -wrap -wrap-key "$(cat "$CREDENTIALS_DIRECTORY/wrap-key")" \
          -vless -vless-bond
      '';
      LoadCredential = [
        "wrap-key:${config.sops.secrets."vk-turn-proxy/wrap-key".path}"
      ];

      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      KeyringMode = "private";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateMounts = "yes";
      PrivateTmp = "yes";
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RemoveIPC = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallFilter = "@system-service";
      SystemCallArchitectures = "native";
      DevicePolicy = "closed";
    };
  };

  networking.firewall = {
   allowedTCPPorts = [ 443 ]; # xray reality
   allowedUDPPorts = [ 56395 ]; # turn proxy
  };
}

