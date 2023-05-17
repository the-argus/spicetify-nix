{
  lib,
  callPackage,
  spotify,
  spicetify-cli,
  ...
}: theme: let
  spiceLib = callPackage ../lib {};
  spicePkgs = callPackage ../pkgs {};

  # use every app and every extension
  flatten = lib.attrsets.mapAttrsToList (_: value: value);
  apps = flatten (builtins.removeAttrs spicePkgs.apps ["override" "overrideDerivation"]);
  extensions = flatten (builtins.removeAttrs spicePkgs.extensions ["_lib" "override" "overrideDerivation"]);

  config-xpui = spiceLib.xpuiBuilder {
    inherit extensions apps theme;
    cfgXpui = {
      AdditionalOptions = {};
      Patch = {};
      Setting = {};
      Patch = {};
      Backup = {};
    };
    cfgColorScheme = null;
    cfg = {};
  };
in
  spiceLib.spicetifyBuilder {
    inherit spotify config-xpui extensions apps theme;
    spicetify = spicetify-cli;
  }
