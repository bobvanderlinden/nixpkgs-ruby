{ pkgs ? import <nixpkgs> {} }:
{
  getVersion = rubyVersion:
    let
      versions = import ./versions;
      version = builtins.foldl' (parent: segment: parent."${segment}") versions rubyVersion;
      versionMeta = version.meta;
      versionName = builtins.foldl' (versionName: segment: versionName + "." + segment) (builtins.head rubyVersion) (builtins.tail rubyVersion);
    in
    pkgs.ruby.overrideAttrs (super: rec {
      name = "ruby-${version}";
      version = versionName;
      src = pkgs.fetchurl versionMeta;
    });
}
