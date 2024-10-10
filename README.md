# nixpkgs-ruby

A Nix repository with all Ruby versions being kept up-to-date automatically.

Consider this an experiment to make all versions of a tool available in a separate Nixpkgs repo.

## Usage

### Ad-hoc

Open a shell with Ruby 2.7.x available:

```sh
$ nix shell github:bobvanderlinden/nixpkgs-ruby#'"ruby-2.7"'
$ ruby --version
ruby 2.7.7p221 (2022-11-24 revision 168ec2b1e5) [x86_64-linux]
```

Run Ruby 2.7.x interpreter directly:

```sh
$ nix shell github:bobvanderlinden/nixpkgs-ruby#'"ruby-2.7"' --command irb
irb(main):001:0> RUBY_VERSION
=> "2.7.7"
```

### Development shell

When you are in a Ruby project that uses `.ruby-version` and Bundle, you can use the following:

```sh
nix flake init --template github:bobvanderlinden/nixpkgs-ruby#
```

This creates `flake.nix` that includes a development shell with a Ruby version that it reads from `.ruby-version`.

> Note: do make sure to `git add` these files in order for Nix to see them.

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
nix flake init --template github:bobvanderlinden/nixpkgs-ruby#
direnv allow
```

After that every time you enter your project directory, the correct Ruby version is automatically available.

### Package

When you want to use a specific Ruby version inside a Nix expression, you can use `ruby-${version}`.

```nix
{
  inputs = {
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };
  outputs = { self, nixpkgs-ruby }: {
    ...
    # You can now refer to packages like:
    #   nixpkgs-ruby.packages.x86_64-linux."ruby-3"
    #   nixpkgs-ruby.packages.x86_64-linux."ruby-2.7"
    #   nixpkgs-ruby.packages.x86_64-linux."ruby-3.0.1"
  };
}
```

### Overlays

It is also possible to use overlays so that the packages are available in `pkgs` alongside other packages from nixpkgs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };
  outputs = { self, nixpkgs, nixpkgs-ruby }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [
        nixpkgs-ruby.overlays.default
      ];
    };
  in {
    # You can now refer to packages like:
    #   pkgs."ruby-3"
    #   pkgs."ruby-2.7"
    #   pkgs."ruby-3.0.1"
  };
}
```

Note that when using overlays, the Ruby packages are built against the nixpkgs that you have specified. `nixpkgs-ruby` only tests against a single version of nixpkgs, so when building against a different `nixpkgs` it'll result in a different package hash compared to what `nixpkgs-ruby` builds and tests against.

### Devenv.sh

You can also use `nixpkgs-ruby` in [devenv.sh](https://devenv.sh). First add `nixpkgs-ruby` to `devenv.yaml`:

```yaml
inputs:
  nixpkgs:
    url: github:NixOS/nixpkgs/nixpkgs-unstable
  nixpkgs-ruby:
    url: github:bobvanderlinden/nixpkgs-ruby
    inputs:
      nixpkgs:
        follows: nixpkgs
```

Next, use a specific Ruby package in `devenv.nix`:

```nix
{ pkgs, nixpkgs-ruby, ... }:
{
  languages.ruby.enable = true;
  languages.ruby.package = nixpkgs-ruby.packages.${pkgs.system}."ruby-2.7";
}
```

### Development shell (without flakes)

When you want to use `nix-shell` with a `shell.nix` or `default.nix` file, use an expression like:

```nix
{ nixpkgs ? import <nixpkgs>
, pkgs ? nixpkgs {}
, nixpkgs-ruby ? import (builtins.fetchTarball {
    url = "https://github.com/bobvanderlinden/nixpkgs-ruby/archive/c1ba161adf31119cfdbb24489766a7bcd4dbe881.tar.gz";
  })
, ruby ? nixpkgs-ruby.packages.${builtins.currentSystem}."ruby-3.2.2"
}:
pkgs.mkShell {
  buildInputs = [
    ruby
  ];
}
```
