{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.initialPassword = "anasisthetallestpersonintheworld";
  users.users.root.openssh.authorizedKeys.keys =
  [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINXAR/j9KQFpumgVdgDPJ+7ayQ7PL1XxMxYas63vmCx2"
  ]; # this is used for unit-testing this module and can be removed if not needed

  services.qemuGuest.enable = true;

  # The loopback network interface
  #auto lo
  #iface lo inet loopback
  #
  # The primary network interface
  #auto ens3
  #iface ens3 inet static
  #    address   62.109.25.255
  #    netmask   255.255.255.255
  #    gateway   10.0.0.1
  #    hwaddress ether 52:54:00:15:D2:10
  #    dns-nameservers 2a01:230:1:1::229 2a01:230:1:1::230 188.120.247.2 188.120.247.8 82.146.59.250 185.60.132.11

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks.ens3 = {
      name = "ens3";
      address = [ "62.109.25.255" ];
      gateway = [ "10.0.0.1" ];
      dns = [ "2a01:230:1:1::229" "2a01:230:1:1::230" "188.120.247.2" "188.120.247.8" "82.146.59.250" "185.60.132.11" ];
    };
  };

  system.stateVersion = "24.05";
}
