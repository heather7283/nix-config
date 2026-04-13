{ lib }:

with builtins; let
  getDirImports = dir: readDir dir
    |> attrNames
    |> filter (file: file != "default.nix")
    |> sort (a: b: a < b)
    |> map (file: "${dir}/${file}")
  ;
in {
  ext = {
    inherit getDirImports;
  } // foldl' (acc: file: acc // (import file { inherit lib; })) {} (getDirImports ./.);
}

