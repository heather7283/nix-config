{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    version = "26.7.11";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    inherit version;

    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-/7vTYVWBJIbw/CaqeHp6shur2cNKHnDzPTVXB4tlVPY=";
    };
    vendorHash = "sha256-Bq9TZ3MSxPrDfs5wfgIHJ4amEhSagHy47/Ldyjs58W8=";

    patches = (old.patches or []) ++ patches;
  });
}

