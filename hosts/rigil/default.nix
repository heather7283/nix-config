{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  users.users.heather = {
    hashedPasswordFile = config.sops.secrets."users/heather/password".path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvIvRUOKHDD9e6ksNw9eM/qXFQrWIVRY4RwqVvJwI/q FA506IH"
    ];
  };

  services.openssh = {
    enable = true;
    # TODO: wg
    listenAddresses = [{ addr = "0.0.0.0"; port = 22; }];
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  # fix sshd starting before wireguard interfce is up
  #systemd.services.sshd.bindsTo = [ "wireguard-wg0.target" ];
  #systemd.services.sshd.after = [ "wireguard-wg0.target" ];

  # some systemd/glibc bloatware nonsense
  system.nssModules = lib.mkForce [];
  services.nscd.enable = false;

  services.giorno = {
    enable = false;
    configFile = config.sops.secrets."giorno/config.toml".path;
    tokenFile = config.sops.secrets."giorno/token.txt".path;
  };

  services.ycurator = {
    enable = false;
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
        443 # https
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
}

