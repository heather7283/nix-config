{ config, ... }:

{
  networking = {
    useDHCP = false;
    useNetworkd = true;

    nftables.enable = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "wg0" ];
      allowedTCPPorts = [
        5201 # iperf3
      ];
      allowedUDPPorts = [
      ];
    };
  };

  systemd.network = {
    enable = true;
    wait-online.enable = true;
  };

  # things I have to do to not flash my VPS' public IP on github :|
  sops.templates."ens3.network" = {
    content = let
      ph = config.sops.placeholder;
    in ''
      [Match]
      Name=ens3

      [Network]
      Address=${ph."ip/v4/address"}
      Address=${ph."ip/v6/address"}

      [Route]
      Gateway=${ph."ip/v4/gateway"}
      GatewayOnLink=true

      [Route]
      Gateway=${ph."ip/v6/gateway"}
    '';
    path = "/etc/systemd/network/ens3.network";
    mode = "0644";
    restartUnits = [ "systemd-networkd.service" ];
  };
}

