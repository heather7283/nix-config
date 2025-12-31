{
  inputs = let
    followsNixpkgs = url: { inherit url; inputs.nixpkgs.follows = "nixpkgs"; };
  in {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-secrets.url = "git+ssh://git@github.com/heather7283/nix-secrets.git?shallow=1";

    sops-nix = followsNixpkgs "github:Mic92/sops-nix";
    disko = followsNixpkgs "github:nix-community/disko";
    giorno = followsNixpkgs "git+ssh://git@github.com/heather7283/giorno.git";
  };
  outputs = {
    self,
    nixpkgs,
    nix-secrets,
    ...
  } @ inputs: let
    # extend lib with custom functions from ./lib directory
    lib = nixpkgs.lib // import ./lib { inherit (nixpkgs) lib; };

    genHost = hostname: lib.nixosSystem {
      specialArgs = {
        inherit lib nix-secrets;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.giorno.nixosModules.giorno
        ./overlays
        ./modules
        ./common
        ./hosts/${hostname}
      ];
    };
  in with builtins; {
    nixosConfigurations = mapAttrs (host: _: genHost host) (readDir ./hosts);
  };
}

