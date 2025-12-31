{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    shellInit = lib.concatLines [
      "export ZDOTDIR=\"$HOME\"/.config/zsh/" # zshenv
    ];
  };
}

