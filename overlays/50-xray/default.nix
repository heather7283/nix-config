{ lib, ... }:

final: prev: {
  # apparently if I don't do this the entire `unstable` attrset get overwritten
  unstable = prev.unstable // {
    xray = prev.unstable.xray.overrideAttrs (old: let
      version = "26.5.9";
      patches = with builtins; readDir ./patches |> attrNames |> map (p: ./patches/${p});
    in {
      inherit version;

      src = final.fetchFromGitHub {
        owner = "XTLS";
        repo = "Xray-core";
        rev = "v${version}";
        hash = "sha256-5krtsy9bUVh7ONxuINAgpm4JmdjtQVBN4w0x3dJDHVo=";
      };
      vendorHash = "sha256-cmfHiX/MmiCWC1vxd7rkCegxMdGiFUUvfncHObQ0zKc=";

      patches = (old.patches or []) ++ patches;
    });
  };
}

