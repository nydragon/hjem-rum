{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum anything attrsOf;
  inherit (lib.generators) toGitINI;

  cfg = config.rum.programs.git;
in {
  options.rum.programs.git = {
    enable = mkEnableOption "git";

    package = mkPackageOption pkgs "git" {};

    settings = mkOption {
      type = attrsOf (attrsOf anything);
      default = {};
      example = {
        user = {
          email = "alice@example.com";
          name = "alice";
        };
        init = {
          defaultBranch = "main";
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
      description = ''
        Settings that will be written to your configuration file.
      '';
    };

    destination = mkOption {
      type = enum [
        ".gitconfig"
        ".config/git/config"
      ];
      default = ".gitconfig";
      description = ''
        Select your preferred git config location. Do note that ~.gitconfig
        takes precedence over .config/git/config.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.${cfg.destination}.text = mkIf (cfg.settings != {}) (toGitINI cfg.settings);
  };
}
