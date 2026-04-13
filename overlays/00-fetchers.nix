final: prev: let
  fetchGitHubRelease = { owner, repo, tag, asset, sha256 }: final.fetchurl {
    url = "https://github.com/${owner}/${repo}/releases/download/${tag}/${asset}";
    inherit sha256;
  };
in {
  ext = {
    inherit fetchGitHubRelease;
  };
}

