{
  description = "mkRuby to build a version of Ruby";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  outputs =
    { self
    , nixpkgs
    , flake-utils
    }: {
      lib = {
        versions = import ./versions;
        getRubyVersionEntry = rubyVersion:
          builtins.foldl' (parent: segment: parent.${segment}) self.lib.versions
            (builtins.splitVersion rubyVersion);
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
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      mkRuby = self.lib.mkRuby;
    in
    {
      packages = {
        ruby-3_2 = mkRuby {
          rubyVersion = "3.2.*";
          inherit pkgs;
        };
        ruby-3_1 = mkRuby {
          rubyVersion = "3.1.*";
          inherit pkgs;
        };
        ruby-3_0 = mkRuby {
          rubyVersion = "3.0.*";
          inherit pkgs;
        };
        ruby-2_7 = mkRuby {
          rubyVersion = "2.7.*";
          inherit pkgs;
        };
        ruby-2_6 = mkRuby {
          rubyVersion = "2.6.*";
          inherit pkgs;
        };
        ruby-2_5 = mkRuby {
          rubyVersion = "2.5.*";
          inherit pkgs;
        };
        ruby-2_4 = mkRuby {
          rubyVersion = "2.4.*";
          inherit pkgs;
        };
        ruby-2_3 = mkRuby {
          rubyVersion = "2.3.*";
          inherit pkgs;
        };
        ruby-2_2 = mkRuby {
          rubyVersion = "2.2.*";
          inherit pkgs;
        };
        ruby-2_1 = mkRuby {
          rubyVersion = "2.1.*";
          inherit pkgs;
        };
        ruby-2_0 = mkRuby {
          rubyVersion = "2.0.*";
          inherit pkgs;
        };
        ruby-1_9 = mkRuby {
          rubyVersion = "1.9";
          inherit pkgs;
        };
        ruby-1_8 = mkRuby {
          rubyVersion = "1.8.*.*";
          inherit pkgs;
        };
      };
      defaultPackage = mkRuby {
        rubyVersion = "*";
        inherit pkgs;
      };
      devShells = {
        # The shell for editing this project.
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nixpkgs-fmt
          ];
        };
      };
    });
}
