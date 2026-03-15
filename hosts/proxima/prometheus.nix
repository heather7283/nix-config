{ ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "10.200.200.41";
    port = 9091;
    enabledCollectors = [ "systemd" ];
  };
  systemd.services.prometheus-node-exporter.requires = [ "sys-devices-virtual-net-wg0.device" ];
}

