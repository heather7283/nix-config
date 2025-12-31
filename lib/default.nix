{ lib }:

with builtins; let
  getDirImports = dir: map
    (file: "${dir}/${file}")
    (attrNames (removeAttrs (readDir dir) [ "default.nix" ]))
  ;
in {
  ext = {
    inherit getDirImports;
  } // foldl' (acc: f: acc // (import ./${f} { inherit lib; })) {} (getDirImports ./.);
}

