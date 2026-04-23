{ ... }:

final: prev: {
  zsh = prev.zsh.overrideAttrs (old: let
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
  in {
    patches = (old.patches or []) ++ patches;
    configureFlags = (old.configureFlags or []) ++ [ "--enable-sqlite" ];
    buildInputs = (old.buildInputs or []) ++ (with final.pkgs; [ sqlite pkg-config ]);
  });
}

