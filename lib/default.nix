{ lib }:

with builtins; let
  files = attrNames (removeAttrs (readDir ./.) [ "default.nix" ]);
  functions = foldl' (acc: f: acc // (import ./${f} { inherit lib; })) {} files;
in functions

