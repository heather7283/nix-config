{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.6.22";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-gSVxRCraw1QdrZfFCjXx6o0MS/3BvXEUO6d3KqZHEhM=";
    };
    vendorHash = "sha256-4sS3HFLsbusft9UYqmMmIRSJl6LJRnav+d8y6d7B7fY=";

    patches = (old.patches or []) ++ patches;
  });
}

