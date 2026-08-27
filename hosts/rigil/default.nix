{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  users.users.heather.hashedPasswordFile = config.sops.secrets."users/heather/password".path;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = false;

  ext.zram.enable = true;

  services.giorno = {
    enable = false;
    configFile = config.sops.secrets."giorno/config.toml".path;
    tokenFile = config.sops.secrets."giorno/token.txt".path;
  };

  services.ycurator = {
    enable = true;
    keyFile = config.sops.secrets."ycurator/authorized_key.json".path;
    configFile = config.sops.secrets."ycurator/config.json".path;
  };

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

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
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

  virtualisation.quadlet = {
    enable = true;
    autoUpdate = {
      enable = true;
      startAt = "*-*-* 08:00:00 Europe/Samara";
    };
  };
}

