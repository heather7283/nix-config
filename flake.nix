{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

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
    nix-secrets,
    ...
  } @ inputs: let
    # extend lib with functions from ./lib directory and put them under lib.ext
    lib = nixpkgs.lib // { ext = import ./lib { lib = nixpkgs.lib; }; };

    genHost = hostname: lib.nixosSystem {
      specialArgs = {
        inherit lib nix-secrets;
      };
      modules = [
        ./common
        ./hosts/${hostname}
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
      ];
    };
  in with builtins; {
    nixosConfigurations = mapAttrs (host: _: genHost host) (readDir ./hosts);
  };
}

