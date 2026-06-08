{ ... }:

final: prev: {
  curlSane = prev.curl.override {
    # https://github.com/NixOS/nixpkgs/issues/451543
    # https://github.com/NixOS/nixpkgs/pull/462692
    # https://github.com/NixOS/nixpkgs/issues/462625
    c-aresSupport = true;
  };
}

