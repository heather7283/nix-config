{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets.url = "git+ssh://git@github.com/heather7283/nix-secrets.git?shallow=1";
  };
  outputs = {
    self,
    nixpkgs,
    sops-nix,
    disko,
    nix-secrets,
    ...
  } @ inputs: let
    # extend lib with functions from ./lib directory and put them under lib.ext
    lib = nixpkgs.lib // { ext = import ./lib { lib = nixpkgs.lib; }; };

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

    genHost = hostname: lib.nixosSystem {
      specialArgs = {
        inherit lib nix-secrets;
      };
      modules = [
        { nixpkgs.overlays = [ xray-overlay ]; }
        ./common
        ./hosts/${hostname}
        ./modules
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
      ];
    };
  in with builtins; {
    nixosConfigurations = mapAttrs (host: _: genHost host) (readDir ./hosts);
  };
}

