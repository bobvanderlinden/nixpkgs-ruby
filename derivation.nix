{ url, sha256, version, ... }: pkgs: pkgs.callPackage ./lib/default.nix  {
  inherit (pkgs.darwin.apple_sdk.frameworks) Foundation;
} {
  version = let
    rubyVersion = pkgs.callPackage ./lib/ruby-version.nix { };
  in
    rubyVersion
      (builtins.elemAt version 0)
      (builtins.elemAt version 1)
      (builtins.elemAt version 2)
      (builtins.elemAt version 3);
  rubySrc = pkgs.fetchurl {
    inherit url sha256;
  };
}