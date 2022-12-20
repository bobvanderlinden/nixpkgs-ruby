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
      versions = builtins.fromJSON (builtins.readFile ./versions.json);
      applyOverrides = import ./lib/apply-overrides.nix;
      versionComparison = import ./lib/version-comparison.nix;
      mkPackages = pkgs:
        let
          overrides = pkgs.callPackage ./overrides.nix { inherit versionComparison; };
          rubygemsSrcs = {
            "2.6" = pkgs.callPackage ./lib/rubygems/2.6.nix { };
            "2.7" = pkgs.callPackage ./lib/rubygems/2.7.nix { };
            "3.0" = pkgs.callPackage ./lib/rubygems/3.0.nix { };
          };
          packageFn = { version, source }:
            let pkg =
              pkgs.callPackage ./lib/default.nix {
                inherit version;
                rubySrc = pkgs.fetchurl source;
                rubygemsSrc =
                  let
                    rubygemsVersion = with (import ./lib/version-comparison.nix) version;
                      if lessThan "2.4"
                      then "2.6"
                      else if lessThan "2.5"
                      then "2.7"
                      else "3.0";
                  in
                  rubygemsSrcs.${rubygemsVersion};
              };
            in
            applyOverrides {
              inherit (pkgs) lib;
              inherit overrides version pkg;
            };
          packageVersions = builtins.mapAttrs (version: source: packageFn { inherit version source; }) versions.sources;
          packageAliases = builtins.mapAttrs (alias: version: packageVersions.${version}) versions.aliases;
          packages = nixpkgs.lib.mapAttrs' (version: package: { name = "ruby-${version}"; value = package; }) (packageAliases // packageVersions);
        in
        packages;
    in
    {
      lib = rec {
        mkRuby =
          { pkgs
          , rubyVersion
          }:
          (self.lib.getRubyVersionEntry rubyVersion).derivation {
            inherit pkgs;
          };
      };

      templates.default = {
        path = ./template;
        description = "A standard Nix-based Ruby project";
        welcomeText = ''
          Usage:

          $ nix develop

          See https://github.com/bobvanderlinden/nixpkgs-ruby for more information.
        '';
      };

      overlays.default = final: prev: mkPackages final;
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      packages = mkPackages pkgs;

      checks = {
        inherit (self.packages.${system})
          ruby-3_1
          ruby-3_0
          ruby-2_7
          ruby-2_6
          ruby-2_5
          ruby-2_4
          ruby-2_3;
      };

      devShells = {
        # The shell for editing this project.
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              nixpkgs-fmt
            ];
        };
      };
    });
}
