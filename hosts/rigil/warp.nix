{ pkgs, lib, ... }:

{
  users.users.cloudflare-warp = {
    isNormalUser = false;
    isSystemUser = true;
    group = "cloudflare-warp";
  };
  users.groups.cloudflare-warp = {};

  system.activationScripts.cloudflare-warp = let
    settings_json = pkgs.writeText "settings.json" ''
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
    deps = [ "users" "groups" "binsh" ];
    text = ''
      mkdir -p /var/lib/cloudflare-warp
      chown -R cloudflare-warp:cloudflare-warp /var/lib/cloudflare-warp
      chmod 0700 /var/lib/cloudflare-warp
      ln -sf ${settings_json} /var/lib/cloudflare-warp/settings.json
    '';
  };

  systemd.services.cloudflare-warp = {
    # TODO: reenable
    enable = false;

    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
      Restart = "always";
      RestartSec = 5;
      LogLevelMax = "warning";

      User = "cloudflare-warp";
      Group = "cloudflare-warp";

      StateDirectory = "cloudflare-warp";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "cloudflare-warp";
      RuntimeDirectoryMode = "0700";
      LogsDirectory = "cloudflare-warp";
      LogsDirectoryMode = "0700";
      WorkingDirectory = "/var/lib/cloudflare-warp";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "cloudflare-warp"
  ];
}

