{ nixpkgs ? <nixpkgs> }:

let
  pkgs = import nixpkgs {
    overlays = [ (import ./overlays.nix).default ];
  };
in
pkgs.nixpkgs-ruby
