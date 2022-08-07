{ pkgs, lib, ... }:
let
  spiceTypes = (import ../lib { inherit pkgs lib; }).types;

  # SOURCE --------------------------------------------------------------------
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

  catppuccinSrc = pkgs.fetchgit {
    url = "https://github.com/catppuccin/spicetify";
    rev = "8aaacc4b762fb507b3cf7d4d1b757eb849fcbb52";
    sha256 = "185fbh958k985ci3sf4rdxxkwbk61qmzjhd6m54h9rrsrmh5px69";
  };

  spotifyNoPremiumSrc = pkgs.fetchgit {
    url = "https://github.com/Daksh777/SpotifyNoPremium";
    rev = "a2daa7a9ec3e21ebba3c6ab0ad1eb5bd8e51a3ca";
    sha256 = "1sr6pjaygxxx6majmk5zg8967jry53z6xd6zc31ns2g4r5sy4k8d";
  };

  comfySrc = pkgs.fetchgit {
    url = "https://github.com/Comfy-Themes/Spicetify";
    rev = "45830ed853cc212dec0c053deb34da6aefc25ce5";
    sha256 = "1hb9f1nwf0jw5yvrzy2bshpb89h1aaysf18zvs0g5fmhmvn7ba6s";
  };

  fluentSrc = pkgs.fetchgit {
    url = "https://github.com/williamckha/spicetify-fluent";
    rev = "47c13bfa2983643a14229c5ecbb88d5001c91c6b";
    sha256 = "0pcx9wshrx0hp3rcjrhi7676baskp8r10bcahp6nr105s42d8x5z";
  };

  # EXTENSIONS ----------------------------------------------------------------

  dribbblishExt = {
    filename = "dribbblish.js";
    src = "${officialThemes}/Dribbblish";
  };

  turntableExt = {
    filename = "turntable.js";
    src = "${officialThemes}/Turntable";
  };

  adblock = {
    src = spotifyNoPremiumSrc;
    filename = "adblock.js";
  };

  # THEME GENERATORS ----------------------------------------------------------

  mkCatppuccinTheme = name: {
    ${name} = {
      inherit name;
      src = catppuccinSrc;
      appendName = true;
      requiredExtensions = [
        {
          src = "${catppuccinSrc}/js";
          filename = "${name}.js";
        }
      ];
      injectCss = true;
      replaceColors = true;
      overwriteAssets = true;
    };
  };
  mkComfyTheme = name: {
    ${name} =
      let lname = lib.strings.toLower name; in
      {
        inherit name;
        src = comfySrc;
        appendName = true;
        injectCss = true;
        replaceColors = true;
        overwriteAssets = true;
        requiredExtensions = [
          {
            src = "${comfySrc}/${name}";
            filename = "${lname}.js";
          }
        ];
        extraCommands = ''
          # remove the auto-update functionality
          echo "\n" >> ./Extensions/${lname}.js
          cat ./Themes/${name}/${lname}.script.js >> ./Extensions/${lname}.js
        '';
      };
  };

  # THEMES --------------------------------------------------------------------

  SpotifyNoPremium = {
    name = "SpotifyNoPremium";
    src = spotifyNoPremiumSrc;
    appendName = false;
    requiredExtensions = [ adblock ];
  };

  Fluent = {
    name = "Fluent";
    src = fluentSrc;
    appendName = false;
    injectCss = true;
    overwriteAssets = true;
    replaceColors = true;
    patches = {
      "xpui.js_find_8008" = ",(\\w+=)32";
      "xpui.js_repl_8008" = ",$\{1}56";
    };
    requiredExtensions = [
      {
        src = fluentSrc;
        filename = "fluent.js";
      }
    ];
  };

  # OFFICIAL THEMES AND EXTENSIONS --------------------------------------------

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
  themes = {
    inherit SpotifyNoPremium Fluent;
  } // official.themes
  // mkCatppuccinTheme "catppuccin-mocha"
  // mkCatppuccinTheme "catppuccin-frappe"
  // mkCatppuccinTheme "catppuccin-latte"
  // mkCatppuccinTheme "catppuccin-macchiato"
  // mkComfyTheme "Comfy"
  // mkComfyTheme "Comfy-Chromatic"
  // mkComfyTheme "Comfy-Mono";
  extensions = {
    "adblock.js" = adblock;
  } // official.extensions;
  apps = { } // official.apps;
}
