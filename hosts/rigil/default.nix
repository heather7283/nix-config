{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  users.users.heather = {
    hashedPasswordFile = config.sops.secrets."users/heather/password".path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICpdk79pzgahzN3CMCWMxWafgINDPWxwtQFt4okXpIAi FA506IH"
    ];
  };

  services.openssh = {
    enable = true;
    listenAddresses = [{ addr = "10.200.200.1"; port = 60322; }];
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # network usage monitoring
  services.vnstat.enable = true;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = false;

  services.resolved.enable = lib.mkForce false;

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

    # DO NOT USE. Does not work properly with my custom port forwarding rules
    nftables.enable = false;

    resolvconf = {
      enable = false;
      useLocalResolver = true;
    };

    firewall = {
      enable = true;
      trustedInterfaces = [ "awg0" ];
      allowedTCPPorts = [
        443 # https
      ];
      allowedUDPPorts = [
        51820 # wireguard
      ];
      logRefusedConnections = false; # pollutes logs a lot
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

      [Route]
      Gateway=${ph."ip/v4/gateway"}
      GatewayOnLink=true
    '';
    path = "/etc/systemd/network/ens3.network";
    mode = "0644";
    restartUnits = [ "systemd-networkd.service" ];
  };
}

