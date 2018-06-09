# nixpkgs-ruby
A Nix repository with all Ruby versions being kept up-to-date automatically.

Consider this an experiment to make all versions of a tool available in a seperate Nixpkgs repo.


## Usage

```
{ pkgs, stdenv, fetchFromGitHub }:
let
  nixpkgsRubySource = fetchFromGitHub {
    owner = "bobvanderlinden";
    repo = "nixpkgs-ruby";
    rev = "aaf2d46c7e166fd4cd52cc71720b72eef2486f18";
    sha256 = "10rbw0kmbgq3jc2gngxqkdb6x4dkrh4fyrfqn6bx864vd4cszh5z";
  };
in
rec {
  nixpkgsRuby = import nixpkgsRubySource { inherit pkgs; };
  rubyVersion = nixpkgsRuby.getVersion;

  # Make your own easy-to-access attributes for the versions you use:
  ruby_2_5_1 = rubyVersion ["2" "5" "1"];
  ruby_2_4_4 = rubyVersion ["2" "4" "4"];

  # ... or use it directly as buildInput in your derivation:
  example = stdenv.mkDerivation {
    name = "example";
    buildInputs = [ (rubyVersion ["2" "5" "1"]) ];
    installPhase = ''
      ruby --version > $out
    '';
  };
}
```
