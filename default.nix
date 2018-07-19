{ pkgs ? import <nixpkgs> { } }:
{
  mkDerivationForRubyVersion = rubyVersion:
    let
      versions = import ./versions;
      version = builtins.foldl' (parent: segment: parent."${segment}") versions rubyVersion;
    in
    version.derivation pkgs;
}