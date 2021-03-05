{
  description = "mkRuby to build a version of Ruby";

  inputs.rvm-patchsets.url = "github:skaes/rvm-patchsets";
  inputs.rvm-patchsets.flake = false;
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  outputs = { self, nixpkgs, flake-utils, rvm-patchsets }: {
    lib.versions = import ./versions;
    lib.getRubyVersionEntry = rubyVersion:
      builtins.foldl' (parent: segment: parent."${segment}") self.lib.versions
      (builtins.splitVersion rubyVersion);
    lib.mkRuby = { pkgs, rubyVersion }:
      let rubyVersionEntry = self.lib.getRubyVersionEntry rubyVersion;
      in rubyVersionEntry.derivation {
        pkgs = pkgs;
        rvm-patchsets = rvm-patchsets;
      };
    packages.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      mkRuby = self.lib.mkRuby;
    in {
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
    defaultPackage.x86_64-linux = self.lib.mkRuby {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      rubyVersion = "*";
    };
  };
}
