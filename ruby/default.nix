{
  versions = builtins.fromJSON (builtins.readFile ./versions.json);
  overridesFn = ./overrides.nix;
  packageFn = ./package-fn.nix;
}