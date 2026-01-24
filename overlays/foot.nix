{ lib, pkgs, config, ... }:

let
  foot-overlay = final: prev: {
    foot = prev.foot.overrideAttrs (old: {
      # install foot's own terminfo files as foot-{,direct-}extra as on other distros
      mesonFlags = old.mesonFlags ++ [ "-Dterminfo-base-name=foot-extra" ];
    });
  };
in {
  nixpkgs.overlays = [ foot-overlay ];
}

