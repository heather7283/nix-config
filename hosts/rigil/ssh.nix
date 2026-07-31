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
    # NOTE: some modules (fail2ban, firewall) only check this option (and NOT listenAddresses)
    ports = [ sshPort ];
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.fail2ban.enable = true;
}

