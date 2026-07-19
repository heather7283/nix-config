{ config, lib, pkgs, hostname, ... }:

{
  imports = lib.ext.getDirImports ./.;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
    auto-optimise-store = true;
    extra-substituters = [
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # passed as an extra argument from flake.nix
  networking.hostName = hostname;

  # Select internationalisation properties.
  i18n.defaultLocale = "C.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    mutableUsers = false;
    users.heather = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      shell = pkgs.zsh;
      packages = with pkgs; [ fzf btop ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    age
    sops
    curlSane # see overlays/50-curl.nix
    rsync
    python3
    libarchive # bsdtar
    foot.terminfo # so that ssh doesn't explode
    nh
  ];

  systemd.settings.Manager = {
    # https://github.com/systemd/systemd/issues/5356
    StatusUnitFormat = "combined";
    # https://michael.stapelberg.ch/posts/2024-01-17-systemd-indefinite-service-restarts/
    DefaultRestartSec = 3;
    DefaultStartLimitIntervalSec = 0;
  };

  programs.less.commands = {
    h = "left-scroll";
    l = "right-scroll";
  };

  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;

  security = {
    sudo.extraConfig = builtins.concatStringsSep "\n" [
      "Defaults lecture = never"
      "Defaults env_keep += \"LESSKEYIN_SYSTEM\"" # make less pick up system lesskey file
    ];
    loginDefs.settings.FAIL_DELAY = 1;
    pam.services.sudo = {
      nodelay = true;
      failDelay = {
        enable = true;
        delay = 100000; # I might have anger management issues
      };
    };
  };

  environment.etc."inputrc".text = "set editing-mode vi";

  environment.sessionVariables = {
    LESSSECURE_ALLOW = "lesskey"; # systemd runs less in "secure mode"
    NH_SHOW_ACTIVATION_LOGS = "1"; # https://github.com/nix-community/nh/pull/479
  };

  boot.kernel.sysctl = lib.ext.flattenAttrs "." {
    # https://wiki.archlinux.org/title/Sysctl#Enable_TCP_Fast_Open
    net.ipv4.tcp_fastopen = 3;
    # https://wiki.archlinux.org/title/Sysctl#Enable_BBR
    net.core.default_qdisc = "cake";
    net.ipv4.tcp_congestion_control = "bbr";
  };

  virtualisation.oci-containers.backend = "podman";

  system.stateVersion = "25.11"; # Do not change
}

