{ lib, ... }:

final: prev: {
  zsh = prev.zsh.overrideAttrs (old: let
    patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
    sqlite = final.pkgs.sqlite;
  in {
    patches = (old.patches or []) ++ patches;
    buildInputs = (old.buildInputs or []) ++ [ sqlite ]; # is this needed at all?
    postFixup = (old.postFixup or "") + ''
      # thanks box
      patchelf --add-rpath \
        ${lib.getLib sqlite}/lib \
        $out/lib/zsh/${old.version}/x_heather7283/sqlite_history.so
    '';
  });
}

