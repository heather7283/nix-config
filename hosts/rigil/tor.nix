{ ... }:

{
  services.tor = {
    enable = true;
    client.enable = false;

    openFirewall = true;
    enableGeoIP = true;

    relay = {
      enable = true;
      role = "bridge";
    };
    settings = {
      ORPort = 27383;
      ExitRelay = false;
      BridgeRelay = true;
      Nickname = "skebob";

      BandwidthRate = "50 MBits";
      BandwidthBurst = "100 MBits";

      BridgeRecordUsageByCountry = true;

      MetricsPort = "127.0.0.1:27384 prometheus";
      MetricsPortPolicy = "accept 127.0.0.1";
    };
  };
}

