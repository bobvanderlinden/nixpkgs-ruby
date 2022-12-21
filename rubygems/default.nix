{
  versions = builtins.fromJSON (builtins.readFile ./versions.json);
  packageFn = ./package-fn.nix;
  overridesFn = ./overrides.nix;
}
