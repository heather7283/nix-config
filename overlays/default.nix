{ lib, pkgs, config, inputs, ... }:

let
  unstable-overlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      inherit (final) config;
    };
  };
in {
  nixpkgs.overlays = lib.ext.getDirImports ./.
    |> builtins.foldl' (acc: file: acc ++ [ (import file) ]) [ unstable-overlay ]
  ;
}

