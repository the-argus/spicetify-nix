{ pkgs, lib, ... }:
let
  inherit (lib) mkOption types;

  xpui = types.submodule {
    options =
      {
        AdditionalOptions = mkOption {
          type = (types.submodule {
            options = {
              home = mkOption { type = types.bool; default = false; };
              experimental_features = mkOption { type = types.bool; default = false; };
              extensions = mkOption { type = (types.listOf types.str); default = ""; };
              custom_apps = mkOption { type = (types.listOf types.str); default = ""; };
              sidebar_config = mkOption { type = types.bool; default = true; };
            };
          });
        };
        Patch = { };
        Setting = mkOption {
          type = (types.submodule {
            options = {
              spotify_path = mkOption { type = types.str; default = "__REPLACEME__"; };
              prefs_path = mkOption { type = types.str; default = "__REPLACEME2__"; };
              current_theme = mkOption { type = types.str; default = ""; };
              color_scheme = mkOption { type = types.str; default = ""; };
              spotify_launch_flags = mkOption { type = types.str; default = ""; };
              check_spicetify_upgrade = mkOption { type = types.bool; default = false; };
              inject_css = mkOption { type = types.bool; default = false; };
              replace_colors = mkOption { type = types.bool; default = false; };
              overwrite_assets = mkOption { type = types.bool; default = false; };
            };
          });
        };
        Preprocesses = mkOption {
          type = (types.submodule {
            options = {
              disable_upgrade_check = mkOption { type = types.bool; default = true; };
              disable_sentry = mkOption { type = types.bool; default = true; };
              disable_ui_logging = mkOption { type = types.bool; default = true; };
              remove_rtl_rule = mkOption { type = types.bool; default = true; };
              expose_apis = mkOption { type = types.bool; default = true; };
            };
          });
        };
        Backup = mkOption {
          type = (types.submodule {
            options = {
              version = mkOption { type = types.str; default = ""; };
              "with" = mkOption { type = types.str; default = "Dev"; };
            };
          });
        };
      };
  };

  extension = types.submodule {
    options = {
      src = mkOption {
        type = types.path;
        description = "Path to the folder which contains the .js file.";
      };
      filename = mkOption {
        type = types.str;
        description = "Name of the .js file to use.";
        example = "dribbblish.js";
      };
    };
  };

  theme = types.submodule {
    options = rec {
      name = mkOption {
        type = types.str;
        description = "The name of the theme as it will be copied into the spicetify themes directory.";
        example = ''Dribbblish'';
      };
      src = mkOption {
        type = types.path;
        description = "Path to folder containing the theme.";
        example = ''builtins.fetchgit {
                      url = "https://github.com/spicetify/spicetify-themes";
                      rev = "5d3d42f913467f413be9b0159f5df5023adf89af";
                      submodules = true;
                    };'';
      };
      requiredExtensions = mkOption {
        type = types.listOf extension;
        default = [ ];
      };

      appendName = mkOption {
        type = types.bool;
        default = true;
        description = ''Whether or not to append the name of the theme
        to the src file path when copying. For example:
        (with appendName on)
        cp /nix/store/2309435394589320fjirjf032-spicetify-themes/Dribbblish Themes
        (with appendName off)
        cp /nix/store/2309435394589320fjirjf032-spicetify-themes Themes
        '';
      };

      # some config values that can be specified per-theme
      injectCss = mkOption {
        type = types.nullOr types.bool;
      };
      overwriteAssets = mkOption {
        type = types.nullOr types.bool;
      };
      replaceColors = mkOption {
        type = types.nullOr types.bool;
      };
    };
  };
in
{
  inherit theme extension xpui;
}
