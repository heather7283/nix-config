{ pkgs, lib, config, ... }:

{
  systemd.services.cloudflare-warp = let
    settings = pkgs.writeText "settings.json" ''
      {
        "version": 1,
        "always_on": true,
        "operation_mode": {
          "WarpProxy": null
        },
        "dns_log_until": null,
        "proxy_port": 10809,
        "qlog_log_until": null
      }
    '';
  in {
    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
      Restart = "always";
      RestartSec = 5;
      LogLevelMax = "warning";

      LoadCredential = [
        "reg.json:${config.sops.secrets."warp/reg.json".path}"
      ];

      BindReadOnlyPaths = [
        "${settings}:/var/lib/cloudflare-warp/settings.json"
        "/run/credentials/cloudflare-warp.service/reg.json:/var/lib/cloudflare-warp/reg.json"
      ];

      DynamicUser = true;
      StateDirectory = "cloudflare-warp";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "cloudflare-warp";
      RuntimeDirectoryMode = "0700";
      LogsDirectory = "cloudflare-warp";
      LogsDirectoryMode = "0700";
      WorkingDirectory = "/var/lib/cloudflare-warp";

      # know your place, proprietary corporateware
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectProc = "invisible";
      ProtectHostname = "yes:debian";
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;
      PrivateIPC = true;
      RemoveIPC = true;
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
      SystemCallFilter = "@system-service";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "cloudflare-warp"
  ];
}

