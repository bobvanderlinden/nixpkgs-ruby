{
  default = final: _: {
    nixpkgs-ruby = final.callPackage ./nixpkgs-ruby.nix { };
  };
}
