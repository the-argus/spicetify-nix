{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.spicetify;
  spiceLib = import ./lib { inherit pkgs lib; };
  spiceTypes = spiceLib.types;
in
{
  options.programs.spicetify = rec {
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

    themesSrc = mkOption {
      type = types.package;
      default = builtins.fetchgit {
        url = "https://github.com/spicetify/spicetify-themes";
        rev = "5d3d42f913467f413be9b0159f5df5023adf89af";
        submodules = true;
      };
      description = "A package whose contents should be copied into the spicetify themes directory.";
    };

    extraCommands = mkOption {
      type = types.lines;
      default = "";
      description = "Extra commands to be run during the setup of spicetify.";
    };

    thirdPartyThemes = mkOption {
      type = types.attrs;
      default = { };
      description = "A set of themes, indexed by name and containing the path to the theme.";
      example = ''
        {
          Dribbblish = $\{spicetify-themes-git}/Dribbblish;
        }
      '';
    };
    thirdPartyExtensions = mkOption {
      type = types.attrs;
      default = { };
    };
    thirdPartyCustomApps = mkOption {
      type = types.attrs;
      default = { };
    };

    xpui = mkOption {
      type = spiceTypes.xpui;
      default = { };
    };

    # legacy/ease of use options (commonly set for themes like Dribbblish)
    # injectCss = xpui.Setting.inject_css;
    injectCss = xpui.inject_css;
    replaceColors = xpui.Setting.replace_colors;
    overwriteAssets = xpui.Setting.overwrite_assets;
  };

  config = mkIf cfg.enable {
    # install necessary packages for this user
    home.packages = with cfg;
      let
        pipeConcat = foldr (a: b: a + "|" + b) "";
        extensionString = pipeConcat cfg.enabledExtensions;
        customAppsString = pipeConcat cfg.enabledCustomApps;

        config-xpui = builtins.toFile "config-xpui.ini" (spiceLib.createXpuiINI cfg.xpui);

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

            cp -r ${cfg.themesSrc} Themes
            ${pkgs.coreutils-full}/bin/chmod -R a+wr Themes

            # the following command will link themes, but we want to copy so we can have w/r
            # find ${cfg.themesSrc} -maxdepth 1 -type d -exec ln -s {} Themes \;
            mkdir -p Extensions
            ${cfg.extraCommands}
            # copy themes into Themes folder
            ${lineBreakConcat (makeCpCommands "Themes" cfg.thirdPartyThemes)}
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
      ];
  };
}

