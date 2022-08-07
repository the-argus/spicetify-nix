{ pkgs, lib, ... }:
let
  officialThemes = builtins.fetchgit {
    url = "https://github.com/spicetify/spicetify-themes";
    rev = "5d3d42f913467f413be9b0159f5df5023adf89af";
    submodules = true;
  };

  officialSrc = builtins.fetchgit {
    url = "https://github.com/spicetify/spicetify-cli";
    rev = "6f473f28151c75e08e83fb280dd30fadd22d9c04";
    sha256 = "0vw0271vbvpgyb0y97lafc5hqpfy5947zm7r2wlg17f8w94vsfhv";
  };

  spiceTypes = (import ../lib { inherit pkgs lib; }).types;

  dribbblishExt = {
    filename = "dribbblish.js";
    src = /${officialThemes}/Dribbblish;
  };
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
          requiredExtensions = [ dribbblishExt ];
          patches = {
            "xpui.js_find_8008" = ",(\\w+=)32";
            "xpui.js_repl_8008" = ",$\{1}56";
          };
          # injectCss = true;
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

    extensions =
      let
        mkOfficialExt = name: { "${name}.js" = { src = /${officialSrc}/Extensions; filename = "${name}.js"; }; };
      in
      { "dribbblish.js" = dribbblishExt; }
      // mkOfficialExt "autoSkipExplicit"
      // mkOfficialExt "autoSkipVideo"
      // mkOfficialExt "bookmark"
      // mkOfficialExt "fullAppDisplay"
      // mkOfficialExt "keyboardShortcut"
      // mkOfficialExt "loopyLoop"
      // mkOfficialExt "popupLyrics"
      // mkOfficialExt "shuffle+"
      // mkOfficialExt "trashbin"
      // mkOfficialExt "webnowplaying";

    apps = {
      new-releases = {
        src = /${officialSrc}/CustomApps;
        name = "new-releases";
      };
      reddit = {
        src = /${officialSrc}/CustomApps;
        name = "reddit";
      };
      lyrics-plus = {
        src = /${officialSrc}/CustomApps;
        name = "lyrics-plus";
      };
    };
  };
}
