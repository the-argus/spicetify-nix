{
  stdenv,
  callPackage,
  fetchurl,
  undmg,
  xorg,
  spotify,
  makeWrapper,
}:
if stdenv.isDarwin
then
  stdenv.mkDerivation {
    pname = "spotify";

    version = "1.2.17.834.g26ee1129";

    src =
      if stdenv.isAarch64
      then
        (fetchurl {
          url = "https://web.archive.org/web/20230808124344/https://download.scdn.co/SpotifyARM64.dmg";
          sha256 = "sha256-u22hIffuCT6DwN668TdZXYedY9PSE7ZnL+ITK78H7FI=";
        })
      else
        (fetchurl {
          url = "https://web.archive.org/web/20230808124637/https://download.scdn.co/Spotify.dmg";
          sha256 = "sha256-aaYMbZpa2LvyBeXmEAjrRYfYqbudhJHR/hvCNTsNQmw=";
        });

    nativeBuildInputs = [undmg];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r *.app $out/Applications

      runHook postInstall
    '';
  }
else
  stdenv.mkDerivation {
    pname = "spotifywm";
    inherit
      ((callPackage ./_sources/generated.nix {}).spotifywmSrc)
      src
      version
      ;

    buildInputs = [xorg.libX11 makeWrapper];

    installPhase = ''
      mkdir -p $out/lib
      mkdir -p $out/bin
      install -Dm644 spotifywm.so $out/lib

      cp ${spotify}/bin/spotify $out/bin
      wrapProgram $out/bin/spotify \
          --set LD_PRELOAD "$out/lib/spotifywm.so"
      # wrapper for spotifywm nixpkgs compatibility
      ln -sf $out/bin/spotify $out/bin/spotifywm
    '';
  }
