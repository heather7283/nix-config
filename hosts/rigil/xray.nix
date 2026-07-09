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
     "dns": {
      "servers": [{ "address": "127.0.0.1", "port": 53, "finalQuery": true }],
      "queryStrategy": "UseIP",
      "disableCache": true
     },
     "inbounds": [
      {
       "tag": "vnc-tun-in",
       "protocol": "socks",
       "listen": "127.0.0.1",
       "port": 10808,
       "settings": {
        "udp": true
       },
       "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls", "quic" ],
        "routeOnly": true
       }
      }/*,
      {
       "tag": "socks-test-in",
       "protocol": "socks",
       "listen": "127.0.0.1",
       "port": 10888,
       "settings": {
        "udp": true
       }
      }*/,
      {
       "tag": "vless-in",
       "protocol": "vless",
       "listen": "0.0.0.0",
       "port": 8443,
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
       "tag": "warp-out",
       "protocol": "freedom",
       "streamSettings": {
        "sockopt": {
         "mark": 53199 // 0xcfcf
        }
       }
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
         },
         { // vnc
          "action": "allow",
          "network": "tcp",
          "ip": [ "127.0.0.1" ],
          "port": 5900
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
        "ruleTag": "vnc",
        "inboundTag": [ "vless-in" ],
        "ip": [ "127.0.0.1" ],
        "port": 5900,
        "network": "tcp",
        "outboundTag": "direct-out"
       }/*,
       {
        "ruleTag": "socks-test-in-warp-out",
        "inboundTag": [ "socks-test-in" ],
        "outboundTag": "warp-out"
       }*/,
       {
        // this is placed before private block to allow DNS traffic from xray itself
        "ruleTag": "hijack-dns",
        "port": 53,
        "outboundTag": "dns-out"
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
        "ruleTag": "vnc-tun-in-pluto-out",
        "inboundTag": [ "vnc-tun-in" ],
        "outboundTag": "pluto-out"
       }/*,
       {
        "ruleTag": "warp-ips",
        "ip": [ "geoip:ru" ],
        "outboundTag": "warp-out"
       },
       {
        "ruleTag": "warp-domains",
        "domain": [ "geosite:category-ru" ],
        "outboundTag": "warp-out"
       },
       {
        "ruleTag": "warp-vless-route-0001",
        "vlessRoute": 1,
        "outboundTag": "warp-out"
       }*/
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
    package = pkgs.xray;
  };
  systemd.services.xray = {
    serviceConfig = {
      # make sure /var/log/xray exists
      LogsDirectory = "xray";
      # hopefully prioritise vpn over other services (surely that's a good idea)
      Nice = -20;
      CPUSchedulingPolicy = "fifo";
      CPUSchedulingPriority = 99;
    };
  };

  networking = {
    firewall.allowedTCPPorts = [ 443 8443 ];
    nftables.tables.xray-443-redirect = {
      family = "inet";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat;
          iifname ens3 tcp dport 443 redirect to :8443
        }
      '';
    };
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

