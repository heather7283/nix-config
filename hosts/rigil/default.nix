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
    listenAddresses = [{ addr = "0.0.0.0"; port = 60322; }];
    # prevents 22 from being opened, must manually open actual port in firewall
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.xray = {
    enable = true;
    settingsFile = config.sops.secrets."xray-config.jsonc".path;
  };
  systemd.services.xray.serviceConfig.LogsDirectory = "xray";

  # network usage monitoring
  services.vnstat.enable = true;

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = false;

  services.resolved.enable = lib.mkForce false;

  services.jmusicbot = {
    enable = true;
    configFile = config.sops.secrets."jmusicbot-config.txt".path;
  };

  services.giorno = {
    enable = true;
    configFile = config.sops.secrets."giorno/config.toml".path;
    tokenFile = config.sops.secrets."giorno/token.txt".path;
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
        60322 # ssh
      ];
      allowedUDPPorts = [
        51820 # wireguard
      ];
      logRefusedConnections = false; # pollutes logs a lot
    };
  };
  # xray, see https://discourse.nixos.org/t/why-cant-i-get-dns-nameservers-to-stick/59132
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
  '';

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
}

