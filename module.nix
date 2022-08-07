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

    enabledExtensions = mkOption {
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
    enabledCustomApps = mkOption {
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
        allExtensions = map spiceLib.getExtension (cfg.enabledExtensions ++
          (if builtins.typeOf cfg.theme == "set" then
            (if builtins.hasAttr "requiredExtensions" cfg.theme then
              cfg.theme.requiredExtensions
            else
              [ ]
            ) else [ ]
          ) ++ cfg.xpui.AdditionalOptions.extensions);
        allExtensionFiles = map (item: item.filename) allExtensions;
        extensionString = pipeConcat allExtensionFiles;

        # do the same thing again but for customapps this time
        allApps = map spiceLib.getApp (cfg.enabledCustomApps ++ cfg.xpui.AdditionalOptions.custom_apps);
        allAppsNames = map (item: item.name) allApps;
        customAppsString = pipeConcat allAppsNames;

        mkXpuiOverrides =
          let
            createBoolOverride = set: attrName: cfgName:
              if (builtins.hasAttr attrName set) then
                let
                  cfgVal = set.${attrName};
                in
                (if (builtins.typeOf cfgVal == "bool") then
                  { cfgName = cfgVal; }
                else
                  { })
              else
                { };
            createOverride = set: attrName: cfgName:
              if (builtins.hasAttr attrName set) then
                { cfgName = set.${attrName}; }
              else
                { };
          in
          container: {
            AdditionalOptions = {
              extensions = extensionString;
              custom_apps = customAppsString;
            };
            Setting = { }
              // createBoolOverride container "injectCss" "inject_css"
              // createBoolOverride container "replaceColors" "replace_colors"
              // createBoolOverride container "overwriteAssets" "overwrite_assets"
              // createBoolOverride container "sidebarConfig" "sidebar_config"
              # also add the colorScheme as an override if defined in cfg
              // (if container == cfg then createOverride container "colorScheme" "color_scheme" else { });
            Patch = (if container == cfg.theme then container.patches else { });
          };

        # override any values defined by the user in cfg.xpui with values defined by the theme
        overridenXpui1 = builtins.mapAttrs
          (name: value: (lib.trivial.mergeAttrs cfg.xpui.${name} value))
          (mkXpuiOverrides theme);
        # override any values defined by the theme with values defined in cfg
        overridenXpui2 = builtins.mapAttrs
          (name: value: (lib.trivial.mergeAttrs overridenXpui1.${name} value))
          (mkXpuiOverrides cfg);

        config-xpui = builtins.toFile "config-xpui.ini" (spiceLib.createXpuiINI overridenXpui2);

        # INI created, now create the postInstall that runs spicetify
        inherit (pkgs.lib.lists) foldr;
        inherit (pkgs.lib.attrsets) mapAttrsToList;

        # Helper functions
        lineBreakConcat = foldr (a: b: a + "\n" + b) "";

        extensionCommands = lineBreakConcat (map
          (item:
            "cp -r ${item.src}/${item.filename} ./Extensions/${item.filename}"
          )
          allExtensions);

        customAppCommands = lineBreakConcat (map
          (item:
            "cp -r ${(if item.appendName then "${item.src}/${item.name}" else "${item.src}")} ./CustomApps/${item.name}")
          allApps);

        spicetify = "${cfg.spicetifyPackage}/bin/spicetify-cli --no-restart";

        theme = spiceLib.getTheme cfg.theme;
        themePath = spiceLib.getThemePath theme;

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
            mkdir -p Extensions
            mkdir -p CustomApps
            cp -r ${themePath} ./Themes/${theme.name}
            ${pkgs.coreutils-full}/bin/chmod -R a+wr Themes
            # copy extensions into Extensions folder
            ${extensionCommands}
            # copy custom apps into CustomApps folder
            ${customAppCommands}
            
            ${cfg.extraCommands}
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

