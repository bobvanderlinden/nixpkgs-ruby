{ stdenv, fetchurl, fetchpatch }:
stdenv.mkDerivation {
  pname = "rubygems";
  version = "2.6.14";
  src = fetchurl {
    url = "http://production.cf.rubygems.org/rubygems/rubygems-2.6.14.tgz";
    hash = "sha256-QGpF0lhwf1IkGEPpx5Arvc8A5+3D6IzbecRmWbR4Uew=";
  };
  patches = [
    (fetchpatch {
      url =
        "https://github.com/zimbatm/rubygems/compare/v2.6.6...v2.6.6-nix.patch";
      sha256 = "0297rdb1m6v75q8665ry9id1s74p9305dv32l95ssf198liaihhd";
    })
  ];
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
