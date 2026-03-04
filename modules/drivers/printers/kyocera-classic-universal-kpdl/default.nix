{
  stdenv,
  lib,
  fetchzip,
  locality ? "English",
}:
stdenv.mkDerivation rec {
  pname = "kyocera-classic-universal-kpdl";
  version = "3.3";

  src = fetchzip {
    url = "https://downloads.kyoceradocumentsolutions.com.au/Drivers/KyoceraClassicUniversal_signed.zip";
    hash = "sha256-XV0b19i/dJQvEpCF1GtRdW3CYhSy17WmQewNIuZFqqc=";
  };

  installPhase = ''
    mkdir -p $out/share/cups/model/Kyocera
    cp KyoClassicUniversalKPDL_v${version}/${locality}/KyUniL.PPD $out/share/cups/model/Kyocera/Kyocera_Classic_Universal_KPDL.ppd
  '';

  meta = {
    description = "PPD file for generic classic Kyocera drivers(KPDL)";
    homepage = "https://www.kyoceradocumentsolutions.com";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [RedEtherbloom];
    platforms = lib.platforms.linux;
  };
}
