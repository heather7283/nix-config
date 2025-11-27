{ lib, pkgs, config, ... }:

with builtins; let
  files = attrNames (removeAttrs (readDir ./.) [ "default.nix" ]);
  imports = foldl' (acc: f: acc // (import ./${f} { inherit lib; })) {} files;
in imports

