{ lib }:

rec {
  mkRuby = { pkgs, rubyVersion }:
    (pkgs.callPackage ./nixpkgs-ruby.nix {}).ruby."ruby-${rubyVersion}";

  readRubyVersionFile = file:
    let
      contents = lib.strings.fileContents file;
      strippedContents = builtins.head (builtins.match "[[:space:]]*(.*)[[:space:]]*" contents);
      segments = lib.strings.splitString "-" strippedContents;
    in
    if builtins.length segments == 1
    then { rubyEngine = "ruby"; version = builtins.head segments; }
    else {
      rubyEngine = builtins.head segments;
      version = builtins.concatStringsSep "-" (builtins.tail segments);
    };

  # Old version of this had it pass { file, system }
  mkPackageFromRubyVersionFile = rubyPkgs: { file, ... }:
    let
      inherit (readRubyVersionFile file) rubyEngine version;
    in
    rubyPkgs."${rubyEngine}-${version}";

}
