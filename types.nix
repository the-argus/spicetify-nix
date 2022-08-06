{ pkgs, lib, ... }:
let
  inherit (lib) mkOption types;

  makeXpuiSubmodule = allowNull: (types.submodule {
    options =
      let
        mkNullableOption = type: mkOption { type = (if allowNull then (types.nullOr type) else (type)); };
      in
      rec {
        AdditionalOptions = mkOption {
          type = types.submodule {
            options = {
              home = mkNullableOption types.bool;
              experimental_features = mkNullableOption types.bool;
              extensions = mkNullableOption (types.listOf types.str);
              custom_apps = mkNullableOption (types.listOf types.str);
              sidebar_config = mkNullableOption types.bool;
            };
          };
        };
        Patch = { };
        Setting = mkOption {
          type = types.submodule {
            options = {
              spotify_path = mkNullableOption types.str;
              prefs_path = mkNullableOption types.str;
              current_theme = mkNullableOption types.str;
              color_scheme = mkNullableOption types.str;
              spotify_launch_flags = mkNullableOption types.str;
              check_spicetify_upgrade = mkNullableOption types.bool;
              inject_css = mkNullableOption types.bool;
              replace_colors = mkNullableOption types.bool;
              overwrite_assets = mkNullableOption types.bool;
            };
          };
        };
        Preprocesses = mkOption {
          type = types.submodule {
            options = {
              disable_upgrade_check = mkNullableOption types.bool;
              disable_sentry = mkNullableOption types.bool;
              disable_ui_logging = mkNullableOption types.bool;
              remove_rtl_rule = mkNullableOption types.bool;
              expose_apis = mkNullableOption types.bool;
            };
          };
        };
        Backup = mkOption {
          type = types.submodule {
            options = {
              version = mkNullableOption types.str;
              "with" = mkNullableOption types.str;
            };
          };
        };
        # duplicates of other options
        inject_css = Setting.inject_css;
      };
  });
  
  xpui = makeXpuiSubmodule false;
  xpuiOverride = makeXpuiSubmodule true;
  
  theme = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the theme as it will be copied into the spicetify themes directory.";
      };
      src = mkOption {
        type = types.path;
        description = "Path to folder containing the theme.";
      };
      xpuiOverrides = mkOption {
        type = types.nullOr xpuiOverride;
        description = "Xpui config values which need to be set in order for the theme to work.";
      };
    };
  };

  extension = types.submodule {
    options = { };
  };

in
{
  inherit theme extension;
}
