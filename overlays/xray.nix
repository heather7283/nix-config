{ lib, pkgs, config, ... }:

let
  xray-overlay = final: prev: {
    xray = prev.xray.overrideAttrs (old: rec {
      version = "26.2.6";

      src = prev.fetchFromGitHub {
        owner = "XTLS";
        repo = "Xray-core";
        rev = "v${version}";
        hash = "sha256-cyrmKC498PuT4thrsGniUFdbKJFseyoQXg4+icaNyT0=";
      };

      patches = let
        # nixpkgs doesn't have go 1.25.6 yet
        patch = pkgs.writeTextFile {
          name = "patch.patch";
          text = ''
            diff --git a/go.mod b/go.mod
            index 77d8780c..67c402cc 100644
            --- a/go.mod
            +++ b/go.mod
            @@ -1,6 +1,6 @@
             module github.com/xtls/xray-core

            -go 1.25.6
            +go 1.25.5

             require (
                    github.com/apernet/quic-go v0.57.2-0.20260111184307-eec823306178
          '';
        };
      in [
        patch
      ];

      vendorHash = "sha256-9Gk01HouhH3GhAd9vmjWr2UpfxPLTVpJvEbSBBRnRKo=";
    });
  };
in {
  nixpkgs.overlays = [ xray-overlay ];
}

