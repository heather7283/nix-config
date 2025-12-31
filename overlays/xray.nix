{ lib, pkgs, config, ... }:

let
  xray-overlay = final: prev: {
    xray = prev.xray.overrideAttrs (old: rec {
      version = "25.12.2";

      src = prev.fetchFromGitHub {
        owner = "XTLS";
        repo = "Xray-core";
        rev = "v${version}";
        hash = "sha256-QP6sPeh5j8FJ8sBxYLWB/y66BwAjRk+wJiivGC2xEls=";
      };

      vendorHash = "sha256-LzCjzEOREqR108v7zR5jWuDwcrb1K58rpv9RyQUxgic=";
    });
  };
in {
  nixpkgs.overlays = [ xray-overlay ];
}

