{ pkgs, lib, ... }:
let
  customToINI = lib.generators.toINI {
    # specifies how to format a key/value pair
    mkKeyValue = lib.generators.mkKeyValueDefault
      {
        # specifies the generated string for a subset of nix values
        mkValueString = v:
          if v == true then "1"
          else if v == false then "0"
          # else if isString v then ''"${v}"''
          # and delegates all other values to the default generator
          else lib.generators.mkValueStringDefault { } v;
      } "=";
  };

  spicePkgs = import ../pkgs { inherit pkgs lib; };
in
{
  types = import ./types.nix { inherit pkgs lib; };

  createXpuiINI = xpui: (customToINI xpui);

  getThemePath = theme: (if theme.appendName then ${theme.src}/${theme.name} else theme.src);

  # same thing but if its a string it looks it up in the default pkgs
  getThemePathFull = theme:
    if builtins.typeOf theme == "string" then
      (
        if spicePkgs.${theme.name} then
          getThemePath spicePkgs.${theme.name}
        else
          throw "Unknown theme ${theme.name}. Try using the lib.theme type instead of a string."
      )
    else (getThemePath theme);

  getExtensionFile = ext: (
    if builtins.typeOf ext == "string" then
      (if spicePkgs.official.extensions.${ext} then
        spicePkgs.official.extensions.${ext}
      else
        throw "Uknown extension ${ext}. Try using the lib.extension type instead of a string.")
    else
      ext
  );
}
