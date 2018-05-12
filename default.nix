{ pkgs ? import <nixpkgs> {} }:
{
  getVersion = rubyVersion:
    let
      versions = import ./versions;
      version = builtins.foldl' (parent: segment: parent."${segment}") versions rubyVersion;
      versionMeta = version.meta;
    in
    pkgs.ruby.overrideAttrs (super: rec {
      name = "ruby-${version}";
      version = versionMeta.versionName;
      src = pkgs.fetchurl {
        inherit (versionMeta) url sha256;
      };
    });
}
