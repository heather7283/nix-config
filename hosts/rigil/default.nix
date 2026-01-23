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

    enableIPv6 = false;

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
  sops.templates."ens3.network".content = let ip = config.sops.placeholder."ip"; in ''
    [Match]
    Name=ens3

    [Network]
    Address=${ip}/32
    Gateway=10.0.0.1

    [Route]
    Gateway=10.0.0.1
    GatewayOnLink=true
  '';
  environment.etc."systemd/network/ens3.network" = {
    source = config.sops.templates."ens3.network".path;
    mode = "0644";
  };
}

