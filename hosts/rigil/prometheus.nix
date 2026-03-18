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
    scrapeConfigs = let
      inherit (config.services.prometheus) exporters;
    in [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            "${exporters.node.listenAddress}:${toString exporters.node.port}" # rigil
            "10.200.200.41:9091" # proxima
            "10.200.200.50:9091" # pluto
          ];
        }];
      }
      {
        job_name = "v2ray";
        metrics_path = "/scrape";
        static_configs = [{
          targets = [
            "${exporters.v2ray.listenAddress}:${toString exporters.v2ray.port}" # rigil
            "10.200.200.41:9092" # proxima
            "10.200.200.50:9092" # pluto
          ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "10.200.200.1";
        http_port = 3000;
        enable_gzip = true;
      };
      security = {
        admin_user = "heather";
        # For system services the path may also be referenced as "/run/credentials/UNITNAME"
        # in cases where no interpolation is possible, e.g. configuration files of software
        # that does not yet support credentials natively.
        admin_password = "$__file{/run/credentials/grafana.service/admin_password}";
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
    # grafana listens on 10.200.200.1
    requires = [ "sys-devices-virtual-net-awg0.device" ];
    # pass admin password from sops
    serviceConfig.LoadCredential = [
      "admin_password:${config.sops.secrets."grafana/admin_password".path}"
    ];
  };
}

