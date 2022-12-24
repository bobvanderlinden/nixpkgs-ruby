{ lib
, overrides
, version
, pkg
}:
let
  matching = builtins.filter ({ condition, ... }: condition version) overrides;
  apply = pkg: { override, ... }: override pkg;
in
lib.foldl apply pkg matching
