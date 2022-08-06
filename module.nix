{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.spicetify;
  spiceLib = import ./lib { inherit pkgs lib; };
  spiceTypes = spiceLib.types;
  spicePkgs = import ./pkgs { inherit pkgs lib; };
in
{
  options.programs.spicetify = {
    enable = mkEnableOption "A modded Spotify";

    theme = mkOption {
      type = types.oneOf [ types.str spiceTypes.theme ];
      default = "";
    };

    spotifyPackage = mkOption {
      type = types.package;
      default = pkgs.spotify-unwrapped;
      description = "The nix package containing Spotify Desktop.";
    };

    spicetifyPackage = mkOption {
      type = types.package;
      default = pkgs.spicetify-cli;
      description = "The nix package containing spicetify-cli.";
    };

    extraCommands = mkOption {
      type = types.lines;
      default = "";
      description = "Extra commands to be run during the setup of spicetify.";
    };

    thirdPartyExtensions = mkOption {
      type = types.listOf (types.oneOf [ spiceTypes.extension types.str ]);
      default = [ ];
      description = "A list of extensions. Official extensions such as \"dribbblish.js\" can be referenced by string alone.";
      example = ''
        [
            "dribbblish.js"
            "shuffle+.js"
            {
                src = pkgs.fetchgit {
                    url = "https://github.com/LucasBares/spicetify-last-fm";
                    rev = "0f905b49362ea810b6247ac1950a2951dd35632e";
                    sha256 = "1b0l2g5cyjj1nclw1ff7as9q94606mkq1k8l2s34zzdsx3m2zv81";
                };
                filename = "lastfm.js";
            }
        ]
      '';
    };
    thirdPartyCustomApps = mkOption {
      type = types.listOf (types.oneOf [ spiceTypes.app types.str ]);
      default = { };
    };

    xpui = mkOption {
      type = spiceTypes.xpui;
      default = { };
    };

    # legacy/ease of use options (commonly set for themes like Dribbblish)
    # injectCss = xpui.Setting.inject_css;
    injectCss = mkOption { type = lib.types.nullOr lib.types.bool; };
    replaceColors = mkOption { type = lib.types.nullOr lib.types.bool; };
    overwriteAssets = mkOption { type = lib.types.nullOr lib.types.bool; };
    sidebarConfig = mkOption { type = lib.types.nullOr lib.types.bool; };
    colorScheme = mkOption { type = lib.types.nullOr lib.types.str; };
  };

  config = mkIf cfg.enable {
    # install necessary packages for this user
    home.packages = with cfg;
      let
        pipeConcat = foldr (a: b: a + "|" + b) "";
        # take the list of extensions and turn strings into actual extensions
        resolvedExtensions = map spiceLib.getExtensionFile cfg.thirdPartyExtensions;
        # add a theme's required extensions
        allExtensionFiles = ((map (item: item.filename) cfg.thirdPartyExtensions) ++
          (if cfg.theme.requiredExtensions then
            cfg.theme.requiredExtensions
          else
            [ ]
          ));
        extensionString = pipeConcat allExtensionFiles;

        # do the same thing again but for customapps this time
        resolvedApps = map spiceLib.getAppName cfg.enabledCustomApps;
        customAppsString = pipeConcat cfg.enabledCustomApps;

        mkXpuiOverrides =
          let
            createBoolOverride = cfgVal: cfgName:
              (if cfgVal || (builtins.typeOf cfgVal == "bool") then { cfgName = cfgVal; } else { });
            createOverride = cfgVal: cfgName:
              (if cfgVal then { cfgName = cfgVal; } else { });
          in
          container: {
            Setting = { }
              // createBoolOverride container.injectCss "inject_css"
              // createBoolOverride container.replaceColors "replace_colors"
              // createBoolOverride container.overwriteAssets "overwrite_assets"
              // createBoolOverride container.sidebarConfig "sidebar_config"
              # also add the colorScheme as an override if defined in cfg
              // (if container == cfg then createOverride container.colorScheme "color_scheme" else { });
          };

        # override any values defined by the user in cfg.xpui with values defined by the theme
        overridenXpui1 = builtins.mapAttrs
          (name: value: (lib.trivial.mergeAttrs cfg.xpui.${name} value))
          (mkXpuiOverrides theme);
        # override any values defined by the theme with values defined in cfg
        overridenXpui2 = builtins.mapAttrs
          (name: value: (lib.trivial.mergeAttrs overridenXpui1 value))
          (mkXpuiOverrides cfg);

        config-xpui = builtins.toFile "config-xpui.ini" (spiceLib.createXpuiINI overridenXpui2);

        # INI created, now create the postInstall that runs spicetify
        inherit (pkgs.lib.lists) foldr;
        inherit (pkgs.lib.attrsets) mapAttrsToList;

        # Helper functions
        lineBreakConcat = foldr (a: b: a + "\n" + b) "";
        boolToString = x: if x then "1" else "0";
        makeCpCommands = type: (mapAttrsToList (name: path:
          let
            extension = if type == "Extensions" then ".js" else "";
          in
          "cp -r ${path} ./${type}/${name}${extension} && ${pkgs.coreutils-full}/bin/chmod -R a+wr ./${type}/${name}${extension}"));

        spicetify = "${cfg.spicetifyPackage}/bin/spicetify-cli --no-restart";

        # custom spotify package with spicetify integrated in
        spiced-spotify = cfg.spotifyPackage.overrideAttrs (oldAttrs: rec {
          postInstall = ''
            export SPICETIFY_CONFIG=$out/spicetify
            mkdir -p $SPICETIFY_CONFIG
            pushd $SPICETIFY_CONFIG
                
            # create config and prefs
            cp ${config-xpui} config-xpui.ini
            ${pkgs.coreutils-full}/bin/chmod a+wr config-xpui.ini
            touch $out/share/spotify/prefs
                
            # replace the spotify path with the current derivation's path
            sed -i "s|__REPLACEME__|$out/share/spotify|g" config-xpui.ini
            sed -i "s|__REPLACEME2__|$out/share/spotify/prefs|g" config-xpui.ini
            
            mkdir -p Themes
            cp -r ${spiceLib.getThemePathFull cfg.theme} Themes/
            ${pkgs.coreutils-full}/bin/chmod -R a+wr Themes
            
            mkdir -p Extensions
            ${cfg.extraCommands}
            # copy extensions into Extensions folder
            ${lineBreakConcat (makeCpCommands "Extensions" cfg.thirdPartyExtensions)}
            # copy custom apps into CustomApps folder
            ${lineBreakConcat (makeCpCommands "CustomApps" cfg.thirdPartyCustomApps)}
            popd

            pushd $out/share/spotify
            ${lineBreakConcat (makeCpCommands "Apps" cfg.thirdPartyCustomApps)}
            popd
            
            ${spicetify} backup apply
            
            # fix config to point to home directory (not necessary I don't think, but whatever)
            # sed -i "s|$out/share/spotify/prefs|${config.home.homeDirectory}/.config/spotify/prefs|g" $SPICETIFY_CONFIG/config-xpui.ini
          '';
        });
      in
      [
        spiced-spotify
        cfg.spicetifyPackage
      ] ++
      # need montserrat for the BurntSienna theme
      (if cfg.theme == "BurntSienna" ||
      cfg.theme == spicePkgs.official.themes.BurntSienna then
        [ pkgs.montserrat ]
      else
        [ ]);
  };
}

