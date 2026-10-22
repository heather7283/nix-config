{ ... }:

final: prev: {
  masterdnsvpn = (final.callPackage ./package.nix {}).overrideAttrs (old: {
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  });
}

