{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-secrets.url = "git+ssh://git@github.com/heather7283/nix-secrets.git?shallow=1";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    genHost = hostname: lib.nixosSystem {
      specialArgs = {
        inherit lib nix-secrets;
      };
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        giorno.nixosModules.giorno
        ./overlays
        ./modules
        ./common
        ./hosts/${hostname}
      ];
    };
  in {
    nixosConfigurations = mapAttrs (host: _: genHost host) (readDir ./hosts);
  };
}

