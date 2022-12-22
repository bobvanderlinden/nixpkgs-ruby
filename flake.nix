{
  description = "mkRuby to build a version of Ruby";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    let
      applyOverrides = import ./lib/apply-overrides.nix;
      versionComparison = import ./lib/version-comparison.nix;
      mkPackageVersions = { pkgs, versions, overridesFn, packageFn }:
        let
          overrides = pkgs.callPackage overridesFn { inherit versionComparison; };
          versionedPackageFnWithOverrides = { version, versionSource }:
            let pkg =
              pkgs.callPackage packageFn {
                inherit version versionSource;
              };
            in
            applyOverrides {
              inherit (pkgs) lib;
              inherit overrides version pkg;
            };
          packageVersions = builtins.mapAttrs (version: versionSource: versionedPackageFnWithOverrides { inherit version versionSource; }) versions.sources;
          packageAliases = builtins.mapAttrs (alias: version: packageVersions.${version}) versions.aliases;
          packages = nixpkgs.lib.mapAttrs' (version: package: { name = version; value = package; }) (packageAliases // packageVersions);
        in
        packages;
      mkPkgSet = { pname, pkgs, versions, overridesFn, packageFn }:
        let
          packageVersions = mkPackageVersions { inherit versions pkgs overridesFn packageFn; };
        in
        nixpkgs.lib.mapAttrs' (version: package: { name = if version == "" then pname else "${pname}-${version}"; value = package; }) packageVersions;

      _pkgsets = {
        ruby = import ./ruby;
        rubygems = import ./rubygems;
      };

      pkgsets = builtins.mapAttrs
        (name: pkgset: pkgs: mkPkgSet {
          inherit pkgs;
          pname = name;
          inherit (pkgset) versions overridesFn packageFn;
        })
        _pkgsets;
    in
    {
      lib.mkRuby =
        { pkgs
        , rubyVersion
        }:
        (pkgsets.ruby pkgs)."ruby-${rubyVersion}";

      templates.default = {
        path = ./template;
        description = "A standard Nix-based Ruby project";
        welcomeText = ''
          Usage:

          $ nix develop

          See https://github.com/bobvanderlinden/nixpkgs-ruby for more information.
        '';
      };

      overlays =
        let
          pkgsetOverlays = builtins.mapAttrs (name: pkgset: final: prev: pkgset final) pkgsets;
        in
        {
          default = nixpkgs.lib.composeManyExtensions (builtins.attrValues pkgsetOverlays);
        }
        // pkgsetOverlays;

    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
        ];
      };
    in
    {
      packages = nixpkgs.lib.concatMapAttrs (name: pkgset: pkgset pkgs) pkgsets;

      checks =
        let
          mkRubyTest = packageName: package:
            pkgs.runCommand packageName { } ''
              ${package}/bin/ruby -e 'puts "ok"' > $out
            '';
        in
        builtins.mapAttrs mkRubyTest self.packages.${system};

      devShells = {
        # The shell for editing this project.
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              nixpkgs-fmt
            ];
        };
      };

      apps.update = {
        type = "app";
        program =
          let
            inherit (builtins) map attrNames getFlake concatStringsSep filter;
            inherit (nixpkgs.lib) mapAttrsToList filterAttrs;
            pkgsetsToUpdate = filterAttrs (name: pkgset: pkgset ? updater) _pkgsets;
            updateCommand = name: pkgset:
              ''
                echo "Updating ${name}..."
                (cd ${name} && ${pkgs.callPackage pkgset.updater { }}/bin/update)
              '';
            updateCommands = mapAttrsToList updateCommand pkgsetsToUpdate;
            script = pkgs.writeScript "update" ''
              set -o errexit
              ${concatStringsSep "\n" updateCommands}
            '';
          in
          "${script}";
      };
    });
}
