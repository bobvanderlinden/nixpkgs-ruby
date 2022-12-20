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
      mkPackageVersions = { pkgs, versions }:
        let
          overrides = pkgs.callPackage ./overrides.nix { inherit versionComparison; };
          packageFn = { version, versionSource }:
            let pkg =
              pkgs.callPackage ./lib/default.nix {
                inherit version versionSource;
              };
            in
            applyOverrides {
              inherit (pkgs) lib;
              inherit overrides version pkg;
            };
          packageVersions = builtins.mapAttrs (version: versionSource: packageFn { inherit version versionSource; }) versions.sources;
          packageAliases = builtins.mapAttrs (alias: version: packageVersions.${version}) versions.aliases;
          packages = nixpkgs.lib.mapAttrs' (version: package: { name = version; value = package; }) (packageAliases // packageVersions);
        in
        packages;
      mkPackages = { pname, pkgs, versions }:
        let
          packageVersions = mkPackageVersions { inherit versions pkgs; };
        in
        nixpkgs.lib.mapAttrs' (version: package: { name = "${pname}-${version}"; value = package; }) packageVersions;
      mkRubyPackages = pkgs: mkPackages {
        inherit pkgs;
        pname = "ruby";
        versions = builtins.fromJSON (builtins.readFile ./versions.json);
      };
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

      overlays.default = final: prev: mkRubyPackages final;
      overlays.rubygems = final: prev: {
        "rubygems-2_6" = final.callPackage ./lib/rubygems/2.6.nix { };
        "rubygems-2_7" = final.callPackage ./lib/rubygems/2.7.nix { };
        "rubygems-3_0" = final.callPackage ./lib/rubygems/3.0.nix { };
        rubygems = final."rubygems-3_0";
      };
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.rubygems
        ];
      };
    in
    {
      packages = mkRubyPackages pkgs;

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
