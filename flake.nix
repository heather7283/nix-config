{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets.url = "git+ssh://git@github.com/heather7283/nix-secrets.git?shallow=1";
  };
  outputs = inputs@{ self, nixpkgs, sops-nix, nix-secrets, ... }: {
    nixosConfigurations = {
      Proxima = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit nix-secrets;
        };
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.sops
        ];
      };
    };
  };
}

