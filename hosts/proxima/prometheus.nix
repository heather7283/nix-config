{ ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "10.20.30.41";
    port = 9091;
    enabledCollectors = [ "systemd" ];
  };
  systemd.services.prometheus-node-exporter.bindsTo = [ "wireguard-wg0.target" ];
  systemd.services.prometheus-node-exporter.after = [ "wireguard-wg0.target" ];
}

