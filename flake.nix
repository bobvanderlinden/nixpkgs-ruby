{
  description = "mkRuby to build a version of Ruby";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;

  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys = "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
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
        rubygems = import ./rubygems;
        ruby = import ./ruby;
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

      lib.readRubyVersionFile = file:
        let
          contents = nixpkgs.lib.strings.fileContents file;
          strippedContents = builtins.head (builtins.match "[[:space:]]*(.*)[[:space:]]*" contents);
          segments = nixpkgs.lib.strings.splitString "-" strippedContents;
        in
          if builtins.length segments == 1
          then { rubyEngine = "ruby"; version = builtins.head segments; }
          else {
            rubyEngine = builtins.head segments;
            version = builtins.concatStringsSep "-" (builtins.tail segments);
          };
      lib.packageFromRubyVersionFile = { file, system }:
        let
          inherit (self.lib.readRubyVersionFile file) rubyEngine version;
        in
          self.packages.${system}."${rubyEngine}-${version}";

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
          lib = nixpkgs.lib;
          mkTest = { name, command, env ? {}, nativeBuildInputs ? [] }:
            pkgs.runCommand name ({ inherit nativeBuildInputs; } // env) command;
          unbrokenPackages = lib.filterAttrs (name: package: !package.meta.broken) self.packages.${system};
          rubyPackages = lib.filterAttrs
            (name: package: (builtins.match "ruby-[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+" name) != null)
            unbrokenPackages;
          rubyTestAttrs = lib.concatMapAttrs (rubyName: ruby:
            let
              rubyVersion = nixpkgs.lib.removePrefix "ruby-" rubyName;
            in
            {
              "${rubyName}-puts-ok" = {
                nativeBuildInputs = [
                  ruby
                ];
                command = ''
                  ruby -e 'puts "ok"' > $out
                '';
              };
              "${rubyName}-jemalloc" = {
                nativeBuildInputs = [
                  (ruby.override { jemallocSupport = true; })
                ];
                command = ''
                  ruby -e 'puts "ok"' > $out
                '';
              };
              "${rubyName}-mkRuby" = {
                nativeBuildInputs = [
                  (self.lib.mkRuby {
                    inherit pkgs rubyVersion;
                  })
                ];
                command = ''
                  ruby -e 'puts "ok"' > $out
                '';
              };
            } // (lib.optionalAttrs (with versionComparison rubyVersion; greaterOrEqualTo "2.4") {
              # Ruby <2.4 only supports openssl 1.0 and not openssl1.1. openssl 1.0 is not supported by nixpkgs
              # anymore, so we will not support it here.
              "${rubyName}-openssl" = {
                nativeBuildInputs = [
                  ruby
                ];
                command = ''
                  ruby -e 'require "openssl"; puts OpenSSL::OPENSSL_VERSION' > $out
                '';
              };
            }) // (lib.optionalAttrs (with versionComparison rubyVersion; greaterOrEqualTo "2.2") {
              "${rubyName}-bundlerEnv" = let
                gems = pkgs.bundlerEnv {
                  name = "gemset";
                  inherit ruby;
                  gemfile = ./tests/bundlerEnv/Gemfile;
                  lockfile = ./tests/bundlerEnv/Gemfile.lock;
                  gemset = ./tests/bundlerEnv/gemset.nix;
                  groups = [ "default" "production" "development" "test" ];
                };
              in {
                nativeBuildInputs = [
                  self.packages.${pkgs.system}.${rubyName}
                  gems
                ];
                command = ''
                  ruby -e 'require "foobar"; say' > $out
                '';
              };
            })
          ) rubyPackages;

          testAttrs = rubyTestAttrs // {
            packageFromRubyVersionFileWithoutEngine =
              let
                ruby = self.lib.packageFromRubyVersionFile {
                  file = ./tests/ruby-version-without-engine;
                  inherit system;
                };
              in
                {
                  nativeBuildInputs = [
                    ruby
                  ];
                  command = ''
                    ruby -e 'puts RUBY_VERSION' > $out
                  '';
                };
            packageFromRubyVersionFileWithEngine =
              let
                ruby = self.lib.packageFromRubyVersionFile {
                  file = ./tests/ruby-version-with-engine;
                  inherit system;
                };
              in
                {
                  nativeBuildInputs = [
                    ruby
                  ];
                  command = ''
                    ruby -e 'puts RUBY_VERSION' > $out
                  '';
                };
          };
        in
          lib.mapAttrs (name: testAttrs:
            mkTest ({
              inherit name;
            } // testAttrs)
          ) testAttrs;

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
              #!${pkgs.bash}/bin/bash
              set -o errexit
              ${concatStringsSep "\n" updateCommands}
            '';
          in
          "${script}";
      };
    });
}
