{ pkgs, ... }:

let
  snowflake-capacity = 100;
  snowflake-min-port = 45000;
  # When specifying the range, make sure it's at least 2x as wide
  # as the amount of clients that you are hoping to serve concurrently.
  snowflake-max-port = snowflake-min-port + (snowflake-capacity * 2);
in {
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

  services.snowflake-proxy = {
    enable = true;
    capacity = snowflake-capacity;
    extraFlags = [
      "-metrics" "-metrics-address" "127.0.0.1" "-metrics-port" "9094"
      "-ephemeral-ports-range" "${toString snowflake-min-port}:${toString snowflake-max-port}"
      "-geoipdb" "${pkgs.tor.geoip}/share/tor/geoip"
      "-geoip6db" "${pkgs.tor.geoip}/share/tor/geoip6"
    ];
  };

  networking.firewall.allowedUDPPortRanges = [
    { from = snowflake-min-port; to = snowflake-max-port; }
  ];
}

