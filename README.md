# nixpkgs-ruby
A Nix repository with all Ruby versions being kept up-to-date automatically.

Consider this an experiment to make all versions of a tool available in a seperate Nixpkgs repo.

## Quick-start

When you are in a Ruby project that uses `.ruby-version` and Bundle, you can use the following:

```sh
nix flake init github:bobvanderlinden/templates#ruby
nix develop
```

## Usage

Create a file `flake.nix`.

You can use nixpkgs-ruby as follows:
```
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  inputs.nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
  outputs = { self, nixpkgs-ruby }: let
    pkgs = nixpkgs.legacyPackages.x86_64;
    ruby-2-7 = nixpkgs-ruby.lib.mkRuby { inherit pkgs; rubyVersion = "2.7.1"; };
    ruby-2-6 = nixpkgs-ruby.lib.mkRuby { inherit pkgs; rubyVersion = "2.6.0"; };
  in {
    ...
  };
}
```

