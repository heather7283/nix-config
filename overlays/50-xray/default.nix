{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.6.27";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-NLxG61mCeMwWoNWjDb0JNjMVG5Blp1OnU00RdAkqIdA=";
    };
    vendorHash = "sha256-BSEoAS4jH/Wyosi0xZC7GqgShVmkj2lS5fQQ7p1cT9s=";

    patches = (old.patches or []) ++ patches;
  });
}

