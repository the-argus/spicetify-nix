{ pkgs, lib, ... }:
let
  officialThemes = pkgs.fetchgit {
    url = "https://github.com/spicetify/spicetify-themes";
    rev = "9a2fcb5a545da368e4bf1d8189f58d0f664f3115";
    sha256 = "18gmhahw7k4labygq3a4igqbkwqzlr67s7xvnf75521ynnzpnhca";
  };

  officialSrc = pkgs.fetchgit {
    url = "https://github.com/spicetify/spicetify-cli";
    rev = "6f473f28151c75e08e83fb280dd30fadd22d9c04";
    sha256 = "0vw0271vbvpgyb0y97lafc5hqpfy5947zm7r2wlg17f8w94vsfhv";
  };

  catpuccinSrc = pkgs.fetchgit {
    url = "https://github.com/catppuccin/spicetify";
    rev = "8aaacc4b762fb507b3cf7d4d1b757eb849fcbb52";
    sha256 = "185fbh958k985ci3sf4rdxxkwbk61qmzjhd6m54h9rrsrmh5px69";
  };

  mkCatpuccinTheme = name: {
    ${name} = {
      inherit name;
      src = catpuccinSrc;
      appendName = true;
      requiredExtensions = [
        {
          src = "${catpuccinSrc}/js";
          filename = "${name}.js";
        }
      ];
      injectCss = true;
      replaceColors = true;
      overwriteAssets = true;
    };
  };

  spiceTypes = (import ../lib { inherit pkgs lib; }).types;

  dribbblishExt = {
    filename = "dribbblish.js";
    src = "${officialThemes}/Dribbblish";
  };

  turntableExt = {
    filename = "turntable.js";
    src = "${officialThemes}/Turntable";
  };

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
          injectCss = true;
          replaceColors = true;
          overwriteAssets = true;
          appendName = true;
          sidebarConfig = true;
        };

        Dreary = {
          name = "Dreary";
          src = officialThemes;
          sidebarConfig = true;
          appendName = true;
        };
        Glaze = {
          name = "Glaze";
          src = officialThemes;
          sidebarConfig = true;
          appendName = true;
        };
        Turntable = {
          name = "Turntable";
          src = officialThemes;
          requiredExtensions = [ "fullAppDisplay.js" turntableExt ];
        };
      } //
      mkOfficialTheme "Ziro" //
      mkOfficialTheme "Sleek" //
      mkOfficialTheme "Onepunch" //
      mkOfficialTheme "Flow" //
      mkOfficialTheme "Default" //
      mkOfficialTheme "BurntSienna";

    extensions =
      let
        mkOfficialExt = name: { "${name}.js" = { src = "${officialSrc}/Extensions"; filename = "${name}.js"; }; };
      in
      {
        "dribbblish.js" = dribbblishExt;
        "turntable.js" = turntableExt;
      }
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
        src = "${officialSrc}/CustomApps";
        name = "new-releases";
      };
      reddit = {
        src = "${officialSrc}/CustomApps";
        name = "reddit";
      };
      lyrics-plus = {
        src = "${officialSrc}/CustomApps";
        name = "lyrics-plus";
      };
    };
  };
in
{
  inherit official;
  themes = { } // official.themes
  // mkCatpuccinTheme "catpuccin-mocha"
  // mkCatpuccinTheme "catpuccin-frappe"
  // mkCatpuccinTheme "catpuccin-latte"
  // mkCatpuccinTheme "catpuccin-macchiato";
  extensions = { } // official.extensions;
  apps = { } // official.apps;
}
