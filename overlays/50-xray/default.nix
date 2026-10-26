{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.10.21";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-1FwcB/qZaH7W9b+GSe+CG/s+uStaDjz792OxDc3uAyg=";
    };
    vendorHash = "sha256-o4mKfCGgI4r5ZatnA4AsK4zR0/qOl2qpqCmoJmE2jBQ=";

    patches = (old.patches or []) ++ patches;
  });
}

