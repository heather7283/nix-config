{ ... }:

final: prev: let
  fetchGitHubRelease = { owner, repo, tag, asset, sha256 }: final.fetchurl {
    url = "https://github.com/${owner}/${repo}/releases/download/${tag}/${asset}";
    inherit sha256;
  };

  makeExecutable = orig: final.stdenv.mkDerivation {
    name = "${orig.name}-executable";
    src = orig;
    phases = [ "installPhase" ];
    installPhase = ''
      cp $src $out
      chmod +x $out
    '';
  };
in {
  ext = {
    inherit fetchGitHubRelease makeExecutable;
  };
}

