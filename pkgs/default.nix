{ pkgs, lib, ... }:
let
  officialThemes = builtins.fetchgit {
    url = "https://github.com/spicetify/spicetify-themes";
    rev = "5d3d42f913467f413be9b0159f5df5023adf89af";
    submodules = true;
  };

  spiceTypes = (import ../lib { inherit pkgs lib; }).types;
in
{
  official = {
    themes =
      let
        mkOfficialTheme = themeName: { ${themeName} = { name = themeName; src = officialThemes; }; };
      in
      {
        Dribbblish = {
          name = "Dribbblish";
          src = officialThemes;
          requiredExtensions = [
            {
              filename = "dribbblish.js";
              src = /${officialThemes}/Dribbblish;
            }
          ];
          patches = {
            "xpui.js_find_8008" = ",(\\w+=)32";
            "xpui.js_repl_8008" = ",$\{1}56";
          };
          injectCss = true;
          replaceColors = true;
          overwriteAssets = true;
        };
      } //
      mkOfficialTheme "Ziro" //
      mkOfficialTheme "Sleek" //
      mkOfficialTheme "Onepunch" //
      mkOfficialTheme "Glaze" //
      mkOfficialTheme "Flow" //
      mkOfficialTheme "Dreary" //
      mkOfficialTheme "Default" //
      mkOfficialTheme "BurntSienna";
  };
}
