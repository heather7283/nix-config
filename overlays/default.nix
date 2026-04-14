{ lib, ... }@args:

{
  nixpkgs.overlays = lib.ext.getDirImports ./. |> builtins.concatMap (f: [ ((import f) args) ]);
}

