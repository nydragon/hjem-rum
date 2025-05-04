{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    rumLib = import ./modules/lib/default.nix {inherit (nixpkgs) lib;};
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
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit
            python312Packages.mdformat
            python312Packages.mdformat-footnote
            python312Packages.mdformat-toc
            python312Packages.mdformat-gfm
            self.formatter.${system}
            python312Packages.commitizen
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
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
