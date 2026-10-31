{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.10.31";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-wTKW8XUP/HXWI7e4jbBw3aGSPpPX7KjkxFwLMb9vxSA=";
    };
    vendorHash = "sha256-JLzEYsnhiATt1JpXD0SgFOhhHUFS34JIdBJXg4eAcL0=";

    patches = (old.patches or []) ++ patches;
  });
}

