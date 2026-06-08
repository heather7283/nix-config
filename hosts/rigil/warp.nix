{ pkgs, lib, config, ... }:

let
  netns = "warp";
  veth-outer = "warp-veth-outer";
  veth-inner = "warp-veth-inner";
  veth-outer-ip = "10.111.111.0";
  veth-inner-ip = "10.111.111.1";
in {
  systemd.services.cf-warp-netns = let
    script-up = with pkgs; writeShellApplication {
      name = "cf-warp-netns-up.sh";
      runtimeInputs = [ iproute2 nftables ];
      text = ''
        ip netns add "${netns}"
        ip -n "${netns}" link set lo up

        ip link add "${veth-outer}" type veth peer name "${veth-inner}"
        ip link set "${veth-inner}" netns "${netns}"

        ip link set "${veth-outer}" up
        ip addr add "${veth-outer-ip}/31" dev "${veth-outer}"

        ip -n "${netns}" link set "${veth-inner}" up
        ip -n "${netns}" addr add "${veth-inner-ip}/31" dev "${veth-inner}"

        ip -n "${netns}" route add default via "${veth-outer-ip}" dev "${veth-inner}"

        ip -n "${netns}" rule add iif "${veth-inner}" lookup 0x100cf

        ip netns exec "${netns}" nft -f - <<'EOF'
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            oifname "CloudflareWARP" masquerade
          }
        }
        EOF

        ip route add default via "${veth-inner-ip}" dev "${veth-outer}" table 0xcfcf
        ip rule add fwmark 0xcfcf lookup 0xcfcf
      '';
    };
    script-down = with pkgs; writeShellApplication {
      name = "cf-warp-netns-down.sh";
      runtimeInputs = [ iproute2 ];
      text = ''
        ip link delete "${veth-outer}" || true
        ip netns delete "${netns}" || true
        ip route del default via "${veth-inner-ip}" dev "${veth-outer}" table 0xcfcf || true
        ip rule del fwmark 0xcfcf lookup 0xcfcf || true
      '';
    };
  in {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      ExecStart = lib.getExe script-up;
      ExecStopPost = lib.getExe script-down;
    };
  };

  networking.nftables.tables.warp = {
    family = "inet";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat;
        ip saddr ${veth-inner-ip} oifname "ens3" masquerade
      }
    '';
  };
  networking.firewall.trustedInterfaces = [ veth-outer ];
  networking.firewall.extraReversePathFilterRules = ''
    ct state established,related accept
  '';

  systemd.services.cf-warp = let
    settings-json = pkgs.writeText "warp-settings.json" ''
      {
        "version": 1,
        "always_on": true,
        "dns_log_until": null,
        "qlog_log_until": null
      }
    '';
  in {
    after = [ "network-online.target" "cf-warp-netns.service" ];
    wants = [ "network-online.target" ];
    bindsTo = [ "cf-warp-netns.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
      Restart = "always";
      RestartSec = 5;
      LogLevelMax = "warning";

      NetworkNamespacePath = "/run/netns/warp";

      StateDirectory = "cloudflare-warp";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "cloudflare-warp";
      RuntimeDirectoryMode = "0700";
      LogsDirectory = "cloudflare-warp";
      LogsDirectoryMode = "0700";
      WorkingDirectory = "/var/lib/cloudflare-warp";

      LoadCredential = [
        "reg.json:${config.sops.secrets."warp/reg.json".path}"
      ];
      BindReadOnlyPaths = [
        "${settings-json}:/var/lib/cloudflare-warp/settings.json"
        "/run/credentials/cf-warp.service/reg.json:/var/lib/cloudflare-warp/reg.json"
      ];

      # warp will refuse to connect if it fails to overwrite /etc/resolv.conf,
      # so give it a tiny writable tmpfs in place of /etc to make it happy
      TemporaryFileSystem = "/etc:rw,size=4096,mode=777";

      DynamicUser = true;
      # These are implied by DynamicUser=true
      #RemoveIPC = true;
      #PrivateTmp = "disconnected";
      #NoNewPrivileges = true;
      #RestrictSUIDSGID = true;
      #ProtectSystem = "strict";

      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      ProtectHome = true;
      ProtectProc = "invisible";
      ProtectHostname = "yes:debian";
      ProtectClock = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = "strict";
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
      LockPersonality = true;
      PrivateIPC = true;

      # Warp needs access to TUN
      #PrivateDevices = true;
      # Gives "Failed to allocate user namespace: Operation not permitted" if set
      #PrivatePIDs = true;
      # Gives EPERM on nft/netlink stuff, probably isn't compatible with NetworkNamespacePath=
      #PrivateUsers = "full";

      DevicePolicy = "closed";
      DeviceAllow = "/dev/net/tun rw";
      SystemCallFilter = "@system-service";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "cloudflare-warp"
  ];
}

