{ ... }:

# Thanks to Emilio Perez at https://github.com/NixOS/nixpkgs/pull/483488
final: prev: {
  hev-socks5-tunnel = final.stdenv.mkDerivation rec {
    name = "hev-socks5-tunnel";
    version = "2.15.0";

    src = final.fetchFromGitHub {
      owner = "heiher";
      repo = name;
      rev = "${version}";
      hash = "sha256-AY8ais/f2CIQzs1YnpvbJ69eFz/M+OS1r3TDcAAM19E=";
      fetchSubmodules = true;
    };

    installPhase = ''
      make install INSTDIR=$out
    '';
  };
}

