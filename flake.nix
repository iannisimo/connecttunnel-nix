{
  description = "A flake porting the SonicWall Connect Tunnel vpn client to Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    targetSystems = [ "x86_64-linux" ];
  in {
    nixosModules = {
      connect-tunnel = import ./module.nix;
      default = self.nixosModules.connect-tunnel;
    };

    nixosModule = self.nixosModules.default;

  } // flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    packages = {
      connect-tunnel = pkgs.callPackage ./connect-tunnel.nix {};
      default = self.packages.${system}.connect-tunnel;
    };

    defaultPackage = pkgs.connect-tunnel;
  });
  
}