{
  description = "mkRuby to build a version of Ruby";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils }: {
    lib.mkRuby = { pkgs, rubyVersion }:
      let default = import ./default.nix { inherit pkgs; };
      in default.mkDerivationForRubyVersion (builtins.splitVersion rubyVersion);
  };
}
