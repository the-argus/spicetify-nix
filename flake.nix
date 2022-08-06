{
  description = "A nix flake that provides a home-manager module to configure spicetify with.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    system = "x86_64-linux";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      homeManagerModule = import ./module.nix;

      lib = import ./lib { inherit pkgs lib; };

      pkgs = import ./pkgs { inherit pkgs lib; };
    };
}
