{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.10.17";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-MUeF3LwZ8bN7gEQCDdzgZKg+agYIokxfQ81VWIkXUgY=";
    };
    vendorHash = "sha256-8Cfbzi3kF3kRtARD2dYaWU4KrcFg65tkjSPO3cWrtps=";

    patches = (old.patches or []) ++ patches;
  });
}

