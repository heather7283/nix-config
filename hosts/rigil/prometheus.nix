{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;

    exporters = {
      node = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9091;
        enabledCollectors = [ "systemd" ];
      };
    };

    globalConfig = {
      scrape_interval = "10s";
    };
    extraFlags = [
      # ref: https://stackoverflow.com/questions/59298811/increasing-prometheus-storage-retention
      "--storage.tsdb.retention.time=31d"
    ];

    scrapeConfigs = with builtins; let
      instances = {
        "127.0.0.1" = "rigil";
        "10.20.30.41" = "proxima";
        "10.20.30.50" = "pluto";
      };
      relabel_configs = attrNames instances |> map (ip: {
        source_labels = [ "__address__" ];
        target_label = "instance";
        regex = "${ip}:[0-9]+";
        replacement = getAttr ip instances;
      });
    in map (e: { inherit relabel_configs; } // e) [
      {
        job_name = "node";
        static_configs = [{ targets = attrNames instances |> map (ip: "${ip}:9091"); }];
      }
      {
        job_name = "v2ray";
        metrics_path = "/scrape";
        static_configs = [{ targets = attrNames instances |> map (ip: "${ip}:9092"); }];
      }
      {
        job_name = "tor-bridge";
        metrics_path = "/metrics";
        static_configs = [{ targets = [ "127.0.0.1:27384" ]; }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "10.20.30.1";
        http_port = 3000;
        enable_gzip = true;
      };
      security = {
        admin_user = "heather";
        # For system services the path may also be referenced as "/run/credentials/UNITNAME"
        # in cases where no interpolation is possible, e.g. configuration files of software
        # that does not yet support credentials natively.
        admin_password = "$__file{/run/credentials/grafana.service/admin_password}";
        secret_key = "$__file{/run/credentials/grafana.service/secret_key}";
      };
    };

    provision = {
      enable = true;
      datasources.settings = {
        prune = true;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = let
              inherit (config.services.prometheus) listenAddress port;
            in
              "http://${listenAddress}:${toString port}"
            ;
            isDefault = true;
            editable = false;
          }
        ];
      };

      dashboards.settings.providers = [{
        name = "Provisioned dashboards";
        disableDeletion = true;
        options = {
          path = "/etc/grafana-dashboards";
        };
      }];
    };
  };

  systemd.services.grafana = {
    # Why won't asDropin work here??????????????????????????????????????????
    #overrideStrategy = "asDropin";
    bindsTo = [ "wireguard-wg0.target" ];
    after = [ "network.target" "wireguard-wg0.target" ];
    serviceConfig = {
      LoadCredential = [
        "admin_password:${config.sops.secrets."grafana/admin_password".path}"
        "secret_key:${config.sops.secrets."grafana/secret_key".path}"
      ];
    };
  };
}

