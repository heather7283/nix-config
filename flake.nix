{
  # apparently functions are not allowed in flake inputs so I have to repeat
  # the `inputs.nixpkgs.follows = "nixpkgs";` mantra for every fucking input
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    secrets.url = "git+ssh://git@github.com/heather7283/nix-secrets.git?shallow=1";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    giorno.url = "git+ssh://git@github.com/heather7283/giorno.git";
    giorno.inputs.nixpkgs.follows = "nixpkgs";

    ycurator.url = "git+ssh://git@github.com/heather7283/ycurator.git";
    ycurator.inputs.nixpkgs.follows = "nixpkgs";

    turn-proxy.url = "github:heather7283/turn-proxy/fix-nixos-server-module";
    turn-proxy.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, secrets, ... }@inputs: let
    # extend lib with custom functions from ./lib directory
    lib = nixpkgs.lib // import ./lib { inherit (nixpkgs) lib; };

    genHost = hostname: lib.nixosSystem {
      specialArgs = {
        inherit lib secrets hostname inputs;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.giorno.nixosModules.giorno
        inputs.ycurator.nixosModules.ycurator
        inputs.turn-proxy.nixosModules.server
        ./overlays
        ./modules
        ./common
        ./hosts/${hostname}
      ];
    };
  in with builtins; {
    nixosConfigurations = readDir ./hosts |> mapAttrs (host: _: genHost host);
  };
}

