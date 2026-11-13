{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.11.9";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-1XxY2RnbDY2WrCPpsr/jfx1cFIxcBdx2IDGM3ow9MXc=";
    };
    vendorHash = "sha256-nSczObf9YvQIjNRPym1sV90cGgI9y8jjVTZALlz7za0=";

    patches = (old.patches or []) ++ patches;
  });
}

