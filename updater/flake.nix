{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
  };
  outputs = { dream2nix, ... }:
    dream2nix.lib.makeFlakeOutputs {
      systems = [ "x86_64-linux" ];
      config.projectRoot = ./.;
      source = ./.;
      projects = ./projects.toml;
      settings = [
        {
          subsystemInfo.noDev = true;
          subsystemInfo.nodejs = 14;
        }
      ];
    };
}
