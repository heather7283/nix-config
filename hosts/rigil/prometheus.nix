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
          targets = [ "${exporters.node.listenAddress}:${toString exporters.node.port}" ];
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
  systemd.services.grafana.requires = [ "sys-devices-virtual-net-awg0.device" ];
}

