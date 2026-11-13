{ lib, ... }:

final: prev: {
  xray = prev.unstable.xray.overrideAttrs (old: let
    # since https://github.com/NixOS/nixpkgs/pull/576986, they added a patch
    # that modifies go.{mod,sum} and breaks src overriding. The xray version
    # in nixpkgs-unstable is relatively up-to-date, so leave it like this for
    # now. Be careful when bumping inputs!
    #version = "26.11.9";
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    #inherit version;

    #src = final.fetchFromGitHub {
    #  owner = "XTLS";
    #  repo = "Xray-core";
    #  rev = "v${version}";
    #  hash = "sha256-1XxY2RnbDY2WrCPpsr/jfx1cFIxcBdx2IDGM3ow9MXc=";
    #};
    #vendorHash = "sha256-nSczObf9YvQIjNRPym1sV90cGgI9y8jjVTZALlz7za0=";

    patches = (old.patches or []) ++ patches;
  });
}

