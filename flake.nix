{
  description = "Manage fan for Argon One V2 Raspberry Pi case (based on CPU temp)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      system = "aarch64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      inherit (inputs.nixpkgs) lib;

      python = lib.head (
        inputs.pyproject-nix.lib.util.filterPythonInterpreters {
          inherit (workspace) requires-python;
          inherit (pkgs) pythonInterpreters;
        }
      );

      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = ./.;
      };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      pythonSet =
        (pkgs.callPackage inputs.pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              inputs.pyproject-build-systems.overlays.default
              overlay
            ]
          );
    in
    {
      packages.${system}.default = pythonSet.mkVirtualEnv "argon-fan-manager-env" workspace.deps.default;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.uv
          inputs.self.packages.${system}.default
        ];
        env = {
          UV_NO_SYNC = "1";
          UV_PYTHON = python.interpreter;
          UV_PYTHON_DOWNLOADS = "never";
        };
        shellHook = ''
          unset PYTHONPATH
        '';
      };

      nixosModules.${system}.default =
        { pkgs, ... }:
        {
          systemd.services.argon-fan-manager = {
            description = "Manage fan for Argon One V2 Raspberry Pi case (based on CPU temp)";
            after = [ "multi-user.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Restart = "always";
            serviceConfig.RestartSec = 5;
            script = ''
              ${inputs.self.packages.${pkgs.system}.default}/bin/argon-fan-manager
            '';
          };
        };
    };
}
