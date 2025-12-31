{ lib, pkgs, config, ... }:

{
  imports = lib.ext.getDirImports ./.;
}

