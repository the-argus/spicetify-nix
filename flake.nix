{
  description = "A nix flake that provides a home-manager module to configure spicetify with.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    {
      homeManagerModule = import ./module.nix;

      lib = import ./lib { inherit pkgs lib; };

      pkgs = import ./pkgs { inherit pkgs lib; };
    };
}
