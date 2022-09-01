{
  url,
  sha256,
  version,
  ...
}: {
  pkgs,
  rvm-patchsets,
}: let
  mkRubyVersion = pkgs.callPackage ./lib/ruby-version.nix {};
  rubyVersion =
    mkRubyVersion (builtins.elemAt version 0) (builtins.elemAt version 1)
    (builtins.elemAt version 2) (builtins.elemAt version 3);

  rubygemsSrcs = {
    "2.6" = pkgs.callPackage ./lib/rubygems/2.6.nix {};
    "2.7" = pkgs.callPackage ./lib/rubygems/2.7.nix {};
    "3.0" = pkgs.callPackage ./lib/rubygems/3.0.nix {};
  };
  rubygemsVersion = with pkgs.lib; let
    major = toInt rubyVersion.major;
    minor = toInt rubyVersion.minor;
  in
    if major < 2 || major == 2 && minor <= 4
    then "2.6"
    else if major == 2 && minor < 5
    then "2.7"
    else "3.0";

  rubygemsSrc = rubygemsSrcs.${rubygemsVersion};

  rubySrc = pkgs.fetchurl {inherit url sha256;};
in
  pkgs.callPackage ./lib/default.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) Foundation;
  } {
    inherit rubySrc rubygemsSrc;
    version = rubyVersion;
  }
