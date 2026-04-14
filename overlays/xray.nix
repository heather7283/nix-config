{ ... }:

final: prev: {
  unstable.xray = prev.unstable.xray.overrideAttrs (old: rec {
    version = "26.3.27";

    src = prev.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-tSSoaIKHgLf9ry6p0Y+BM1Nx8X+40BDDfJJYkABUoEc=";
    };

    vendorHash = "sha256-kwvck6Eo/e6qgb1ENznhwZ/GPX75ssLUvR2u8Qm3UIM=";
  });
}

