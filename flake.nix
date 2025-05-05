{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];

    forAllSystems = function:
      nixpkgs.lib.genAttrs
      supportedSystems
      (system: function nixpkgs.legacyPackages.${system});

    rumLib = import ./modules/lib/default.nix {inherit (nixpkgs) lib;};
    treefmtEval = forAllSystems (pkgs:
      treefmt-nix.lib.evalModule pkgs
      {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
        programs.deno.enable = true;

        settings = {
          deno.includes = ["*.md"];
        };
      });
  in {
    hjemModules = {
      hjem-rum = import ./modules/hjem.nix {
        inherit (nixpkgs) lib;
        inherit rumLib;
      };
      default = self.hjemModules.hjem-rum;
    };
    nixosModules = {
      hjem-rum = import ./modules/nixos.nix {
        inherit (nixpkgs) lib;
        inherit rumLib;
      };
      default = self.nixosModules.hjem-rum;
    };

    lib = rumLib;

    devShells = forAllSystems (
      pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit
            python312Packages.commitizen
          ];
          inputsFrom = [
            treefmtEval.${pkgs.system}.config.build.devShell
          ];
          shellHook = ''
            pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
          '';
        };
      }
    );

    # Provides checks to invoke with 'nix flake check'
    checks = forAllSystems (
      system:
        import ./modules/tests {
          inherit self;
          inherit (nixpkgs) lib;
          pkgs = nixpkgs.legacyPackages.${system};
          testDirectory = ./modules/tests/programs;
        }
    );

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
  };
}
