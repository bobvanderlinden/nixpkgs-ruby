{ version
, versionSource
, patches ? []
, stdenv
, fetchurl
, fetchpatch
}:
stdenv.mkDerivation {
  pname = "rubygems";
  inherit version patches;
  src = fetchurl versionSource;
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
