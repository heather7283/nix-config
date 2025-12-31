{
  # apparently functions are not allowed in flake inputs so I have to repeat
  # the `inputs.nixpkgs.follows = "nixpkgs";` mantra for every fucking input
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-secrets.url = "git+ssh://git@github.com/heather7283/nix-secrets.git?shallow=1";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    giorno.url = "git+ssh://git@github.com/heather7283/giorno.git";
    giorno.inputs.nixpkgs.follows = "nixpkgs";
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

