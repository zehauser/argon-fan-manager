{
  description = "Manage fan for Argon One V2 Raspberry Pi case (based on CPU temp)";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      system = "aarch64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };

      # See: https://github.com/nix-community/poetry2nix/blob/4277e49c00037ebe016e641abdcd0a1d1dab7849/docs/edgecases.md#modulenotfounderror-no-module-named-packagename
      poetryOverrides = poetry2nix.defaultPoetryOverrides.extend (
        final: prev: {
          smbus = prev.smbus.overridePythonAttrs (old: {
            buildInputs = old.buildInputs ++ [ prev.setuptools ];
          });
        }
      );

    in

    {
      packages.${system}.default = poetry2nix.mkPoetryApplication {
        projectDir = inputs.self;
        overrides = poetryOverrides;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.poetry ];
        buildInputs = [
          (poetry2nix.mkPoetryEnv {
            projectDir = inputs.self;
            overrides = poetryOverrides;
          })
        ];
      };

      nixosModules.${system}.default =
        { ... }:
        {
          systemd.services.argon-fan-manager = {
            description = "Manage fan for Argon One V2 Raspberry Pi case (based on CPU temp)";
            after = [ "multi-user.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Restart = "always";
            serviceConfig.RemainAfterExit = "true";
            script = ''
              ${inputs.self.packages.${system}.default}/bin/argon-fan-manager
            '';
          };
        };
    };
}
