{ lib
, pkgs
}:

let
  applyOverrides = import ./lib/apply-overrides.nix;
  versionComparison = import ./lib/version-comparison.nix;

  mkPkgSet = { pname, versions, overridesFn, packageFn }:
    let
      packageVersions = mkPackageVersions { inherit versions pkgs overridesFn packageFn; };
    in
    lib.mapAttrs' (version: package: { name = if version == "" then pname else "${pname}-${version}"; value = package; }) packageVersions;

  mkPackageVersions = { pkgs, versions, overridesFn, packageFn }:
    let
      overrides = pkgs.callPackage overridesFn { inherit versionComparison; };
      versionedPackageFnWithOverrides = { version, versionSource }:
        let
          pkg =
            pkgs.callPackage packageFn {
              inherit version versionSource versionComparison;
            };
        in
        applyOverrides {
          inherit (pkgs) lib;
          inherit overrides version pkg;
        };
      packageVersions = builtins.mapAttrs (version: versionSource: versionedPackageFnWithOverrides { inherit version versionSource; }) versions.sources;
      packageAliases = builtins.mapAttrs (alias: version: packageVersions.${version}) versions.aliases;
    in
    packageAliases // packageVersions;

  pkgsets = builtins.mapAttrs
    (name: pkgset: mkPkgSet {
      pname = name;
      inherit (pkgset) versions overridesFn packageFn;
    })
    {
      rubygems = import ./rubygems;
      ruby = import ./ruby;
    };

  allPackages = pkgsets.rubygems // pkgsets.ruby;
  intactPackages = lib.filterAttrs (_: package: lib.isDerivation package && !package.meta.broken) allPackages;

  nixpkgsRubyLib = import ./lib.nix { inherit lib; };
  packageFromRubyVersionFile = nixpkgsRubyLib.mkPackageFromRubyVersionFile pkgsets.ruby;
in
pkgsets // {
  lib = nixpkgsRubyLib // {
    inherit packageFromRubyVersionFile;
  };

  inherit allPackages;
  packages = intactPackages;
}
