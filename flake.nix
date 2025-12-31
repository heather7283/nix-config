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

    giorno = {
      url = "git+ssh://git@github.com/heather7283/giorno.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    sops-nix,
    disko,
    nix-secrets,
    giorno,
    ...
  } @ inputs: with builtins; let
    # extend lib with custom functions from ./lib directory
    lib = nixpkgs.lib // import ./lib { inherit (nixpkgs) lib; };

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

    customModules = map
      (p: ./modules/${p})
      (attrNames (removeAttrs (readDir ./modules) [ "default.nix" ]));

    genHost = hostname: lib.nixosSystem {
      specialArgs = {
        inherit lib nix-secrets;
      };
      modules = customModules ++ [
        { nixpkgs.overlays = [ xray-overlay ]; }
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        giorno.nixosModules.giorno
        ./common
        ./hosts/${hostname}
      ];
    };
  in {
    nixosConfigurations = mapAttrs (host: _: genHost host) (readDir ./hosts);
  };
}

