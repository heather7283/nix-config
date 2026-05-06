{ lib, ... }:

final: prev: {
  # apparently if I don't do this the entire `unstable` attrset get overwritten
  unstable = prev.unstable // {
    xray = prev.unstable.xray.overrideAttrs (old: let
      version = "26.3.27";
      patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
    in {
      inherit version;

      src = final.fetchFromGitHub {
        owner = "XTLS";
        repo = "Xray-core";
        rev = "v${version}";
        hash = "sha256-tSSoaIKHgLf9ry6p0Y+BM1Nx8X+40BDDfJJYkABUoEc=";
      };
      vendorHash = "sha256-kwvck6Eo/e6qgb1ENznhwZ/GPX75ssLUvR2u8Qm3UIM=";

      patches = (old.patches or []) ++ patches;
    });
  };
}

