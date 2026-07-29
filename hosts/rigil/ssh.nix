{ ... }:

let
  sshPort = 58422;
in {
  users.users.heather.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvIvRUOKHDD9e6ksNw9eM/qXFQrWIVRY4RwqVvJwI/q FA506IH"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFg3UfFZJePZTBaPyFxf8aoPaL7MFGBIx+gzhPfgop0G pyxis"
  ];

  services.openssh = {
    enable = true;
    # TODO: wg
    listenAddresses = [{ addr = "0.0.0.0"; port = sshPort; }];
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  # fix sshd starting before wireguard interfce is up
  #systemd.services.sshd.bindsTo = [ "wireguard-wg0.target" ];
  #systemd.services.sshd.after = [ "wireguard-wg0.target" ];

  networking.firewall.allowedTCPPorts = [ sshPort ];

  services.fail2ban.enable = true;
}

