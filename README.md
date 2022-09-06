# nixpkgs-ruby

A Nix repository with all Ruby versions being kept up-to-date automatically.

Consider this an experiment to make all versions of a tool available in a seperate Nixpkgs repo.

## Usage

### Development shell

When you are in a Ruby project that uses `.ruby-version` and Bundle, you can use the following:

```sh
nix flake init github:bobvanderlinden/nixpkgs-ruby#
```

This creates `flake.nix` that includes a development shell with a Ruby version that it reads from `.ruby-version`.

To use the shell use:

```sh
nix develop
```

This opens a new shell where Ruby (and any other build inputs) are available.

To let Nix handle your gems run:

```sh
bundix
```

This creates `gemset.nix` based on your `Gemfile.lock`. You can now uncomment [`gems` in `buildInputs` in `flake.nix`](https://github.com/bobvanderlinden/nixpkgs-ruby/blob/325b4724a801d3f9d0d26852858e30308759f746/template/flake.nix#L29).

### Direnv

[direnv](https://direnv.net/) is a convenient way to automatically load environments into your shell when entering a project directory.

To use this for nixpkgs-ruby, you'll need [nix-direnv](https://github.com/nix-community/nix-direnv).

Once installed, you can do:

```sh
nix flake init github:bobvanderlinden/nixpkgs-ruby#
direnv allow
```

After that every time you enter your project directory, the correct Ruby version is automatically available.

### Package

When you want to use a specific Ruby version inside a Nix expression, you can use `mkRuby` to generate a Ruby package:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };
  outputs = { self, nixpkgs, nixpkgs-ruby }: let
    pkgs = nixpkgs.legacyPackages.x86_64;
    ruby-2_7 = nixpkgs-ruby.lib.mkRuby { inherit pkgs; rubyVersion = "2.7.1"; };
    ruby-2_6 = nixpkgs-ruby.lib.mkRuby { inherit pkgs; rubyVersion = "2.6.0"; };
  in {
    ...
  };
}
```
