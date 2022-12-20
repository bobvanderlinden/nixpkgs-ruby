{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
  };
  outputs = { dream2nix, ... }:
    dream2nix.lib.makeFlakeOutputs {
      systems = [ "x86_64-linux" ];
      config.projectRoot = ./.;
      source = ./.;
      projects.nixpkgs-ruby-updater = {
        name = "nixpkgs-ruby-updater";
        relPath = "";
        subsystem = "nodejs";
        translator = "package-lock";
        translators = [ "package-lock" ];
        subsystemInfo.nodejs = 18;
      };
    };
}
