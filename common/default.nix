{ config, lib, pkgs, ... }:

{
  imports = lib.ext.getDirImports ./.;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Select internationalisation properties.
  i18n.defaultLocale = "C.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    heather = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW47TMs+tXJEl6bY0FGd54kf5DM/g21mfA5tij5JNJc heather@FA506IH"
      ];
      shell = pkgs.zsh;
      packages = with pkgs; [ fzf btop ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    age
    sops
    curl
    rsync
    python3
  ];

  # https://github.com/systemd/systemd/issues/5356
  systemd.settings.Manager = {
      StatusUnitFormat = "combined";
  };

  security.loginDefs.settings = {
    FAIL_DELAY = 1;
  };

  environment.etc."inputrc".text = "set editing-mode vi";

  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    # https://wiki.archlinux.org/title/Sysctl#Enable_TCP_Fast_Open
    net.ipv4.tcp_fastopen = 3;
    # https://wiki.archlinux.org/title/Sysctl#Enable_BBR
    net.core.default_qdisc = "cake";
    net.ipv4.tcp_congestion_control = "bbr";
  };

  system.stateVersion = "25.11"; # Do not change
}

