{
  description = "mkRuby to build a version of Ruby";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;

  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys = "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      applyOverrides = import ./lib/apply-overrides.nix;
      versionComparison = import ./lib/version-comparison.nix;
      mkPackageVersions =
        {
          pkgs,
          versions,
          overridesFn,
          packageFn,
        }:
        let
          overrides = pkgs.callPackage overridesFn { inherit versionComparison; };
          versionedPackageFnWithOverrides =
            { version, versionSource }:
            let
              pkg = pkgs.callPackage packageFn {
                inherit version versionSource versionComparison;
              };
            in
            applyOverrides {
              inherit (pkgs) lib;
              inherit overrides version pkg;
            };
          packageVersions = builtins.mapAttrs (
            version: versionSource: versionedPackageFnWithOverrides { inherit version versionSource; }
          ) versions.sources;
          packageAliases = builtins.mapAttrs (alias: version: packageVersions.${version}) versions.aliases;
        in
        nixpkgs.lib.mapAttrs' (version: package: {
          name = version;
          value = package;
        }) (packageAliases // packageVersions);
      mkPkgSet =
        {
          pname,
          pkgs,
          versions,
          overridesFn,
          packageFn,
        }:
        let
          packageVersions = mkPackageVersions {
            inherit
              versions
              pkgs
              overridesFn
              packageFn
              ;
          };
        in
        nixpkgs.lib.mapAttrs' (version: package: {
          name = if version == "" then pname else "${pname}-${version}";
          value = package;
        }) packageVersions;

      _pkgsets = {
        rubygems = import ./rubygems;
        ruby = import ./ruby;
      };

      pkgsets = builtins.mapAttrs (
        name: pkgset: pkgs:
        mkPkgSet {
          inherit pkgs;
          pname = name;
          inherit (pkgset) versions overridesFn packageFn;
        }
      ) _pkgsets;
    in
    {
      lib.mkRuby =
        {
          pkgs,
          rubyVersion,
        }:
        (pkgsets.ruby pkgs)."ruby-${rubyVersion}";

      lib.readRubyVersionFile =
        file:
        let
          contents = nixpkgs.lib.strings.fileContents file;
          strippedContents = builtins.head (builtins.match "[[:space:]]*(.*)[[:space:]]*" contents);
          segments = nixpkgs.lib.strings.splitString "-" strippedContents;
        in
        if builtins.length segments == 1 then
          {
            rubyEngine = "ruby";
            version = builtins.head segments;
          }
        else
          {
            rubyEngine = builtins.head segments;
            version = builtins.concatStringsSep "-" (builtins.tail segments);
          };

      lib.packageFromRubyVersionFile =
        { file, system }:
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
          pkgsetOverlays = builtins.mapAttrs (
            name: pkgset: final: prev:
            pkgset final
          ) pkgsets;
        in
        {
          default = nixpkgs.lib.composeManyExtensions (builtins.attrValues pkgsetOverlays);
        }
        // pkgsetOverlays;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        lib = nixpkgs.lib;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config.permittedInsecurePackages = [
            "openssl-1.1.1w"
          ];
        };

        allPackages = lib.concatMapAttrs (name: pkgset: pkgset pkgs) pkgsets;
        intactPackages = lib.filterAttrs (name: package: !package.meta.broken) allPackages;
        rubyPackages = lib.filterAttrs (
          name: package: (builtins.match "ruby-[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+" name) != null
        ) intactPackages;
        mkTest =
          {
            name,
            command,
            env ? { },
            nativeBuildInputs ? [ ],
          }:
          pkgs.runCommand name ({ inherit nativeBuildInputs; } // env) command;
        flattenCheckName =
          groupName: testName: if groupName == "common" then testName else "${groupName}-${testName}";
        checkBatchAttrs =
          lib.mapAttrs (
            rubyName: ruby:
            let
              rubyVersion = lib.removePrefix "ruby-" rubyName;
            in
            {
              puts-ok = {
                nativeBuildInputs = [
                  ruby
                ];
                command = ''
                  ruby -e 'puts "ok"' > $out
                '';
              };
              jemalloc = {
                nativeBuildInputs = [
                  (ruby.override { jemallocSupport = true; })
                ];
                command = ''
                  ruby -e 'puts "ok"' > $out
                '';
              };
              mkRuby = {
                nativeBuildInputs = [
                  (self.lib.mkRuby {
                    inherit pkgs rubyVersion;
                  })
                ];
                command = ''
                  ruby -e 'puts "ok"' > $out
                '';
              };
            }
            // (lib.optionalAttrs (with versionComparison rubyVersion; greaterOrEqualTo "2.4") {
              # Ruby <2.4 only supports openssl 1.0 and not openssl1.1. openssl 1.0 is not supported by nixpkgs
              # anymore, so we will not support it here.
              openssl = {
                nativeBuildInputs = [
                  ruby
                ];
                command = ''
                  ruby -e 'require "openssl"; puts OpenSSL::OPENSSL_VERSION' > $out
                '';
              };
            })
            // (lib.optionalAttrs (with versionComparison rubyVersion; greaterOrEqualTo "3.4") {
              docSupport = {
                nativeBuildInputs = [
                  (ruby.override { docSupport = true; })
                ];
                command = ''
                  HOME=$TMPDIR ri Array > $out
                '';
              };
            })
            // (lib.optionalAttrs (with versionComparison rubyVersion; lessThan "3.4") {
              docSupport-noParallel = {
                nativeBuildInputs = [
                  (ruby.override {
                    docSupport = true;
                    parallelBuild = false;
                  })
                ];
                command = ''
                  HOME=$TMPDIR ri Array > $out
                '';
              };
            })
            // (lib.optionalAttrs (with versionComparison rubyVersion; greaterOrEqualTo "2.2") {
              bundlerEnv =
                let
                  gems = pkgs.bundlerEnv {
                    name = "gemset";
                    inherit ruby;
                    gemfile = ./tests/bundlerEnv/Gemfile;
                    lockfile = ./tests/bundlerEnv/Gemfile.lock;
                    gemset = ./tests/bundlerEnv/gemset.nix;
                    groups = [
                      "default"
                      "production"
                      "development"
                      "test"
                    ];
                  };
                in
                {
                  nativeBuildInputs = [
                    self.packages.${pkgs.system}.${rubyName}
                    gems
                  ];
                  command = ''
                    ruby -e 'require "foobar"; say' > $out
                  '';
                };
            })
          ) rubyPackages
          // {
            common = {
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
          };
        mkCheckBatch =
          groupName: batchAttrs:
          let
            batchChecks = lib.mapAttrs (
              testName: attrs:
              mkTest (
                {
                  name = flattenCheckName groupName testName;
                }
                // attrs
              )
            ) batchAttrs;
          in
          batchChecks
          // {
            all = pkgs.linkFarm "${groupName}-checks" (
              lib.mapAttrsToList (testName: checkDrv: {
                name = testName;
                path = checkDrv;
              }) batchChecks
            );
          };
        checkBatches = lib.mapAttrs mkCheckBatch checkBatchAttrs;
        checks = lib.concatMapAttrs (
          groupName: batchChecks:
          lib.mapAttrs' (testName: checkDrv: {
            name = flattenCheckName groupName testName;
            value = checkDrv;
          }) (lib.removeAttrs batchChecks [ "all" ])
        ) checkBatches;
        ghaMatrixEntries =
          (builtins.map (group: {
            os = "ubuntu-latest";
            system = "x86_64-linux";
            inherit group;
          }) (builtins.attrNames self.checkBatches.x86_64-linux))
          ++ (builtins.map (group: {
            os = "macos-latest";
            system = "aarch64-darwin";
            inherit group;
          }) (builtins.attrNames self.checkBatches.aarch64-darwin));
        ghaPrepareMatrix = pkgs.writeShellApplication {
          name = "gha-prepare-matrix";
          text = ''
            matrix=${lib.escapeShellArg (builtins.toJSON ghaMatrixEntries)}

            if [ -n "''${GITHUB_OUTPUT:-}" ]; then
              printf 'matrix=%s\n' "$matrix" >> "$GITHUB_OUTPUT"
            else
              printf 'warning: GITHUB_OUTPUT is not set; writing matrix to stdout\n' >&2
              printf 'matrix=%s\n' "$matrix"
            fi
          '';
        };
      in
      {
        packages = intactPackages // {
          gha-prepare-matrix = ghaPrepareMatrix;
        };

        checkBatches = checkBatches;

        checks = checks;

        formatter = pkgs.nixfmt-tree;

        devShells = {
          # The shell for editing this project.
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nixfmt-tree
            ];
          };
        };

        apps = {
          gha-prepare-matrix = {
            type = "app";
            program = "${ghaPrepareMatrix}/bin/gha-prepare-matrix";
          };

          update = {
            type = "app";
            program =
              let
                inherit (builtins)
                  concatStringsSep
                  ;
                inherit (nixpkgs.lib) mapAttrsToList filterAttrs;
                pkgsetsToUpdate = filterAttrs (name: pkgset: pkgset ? updater) _pkgsets;
                updateCommand = name: pkgset: ''
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
        };
      }
    );
}
