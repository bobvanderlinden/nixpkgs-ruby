{ stdenv, fetchurl, fetchpatch }:
stdenv.mkDerivation {
  pname = "rubygems";
  version = "2.7.6";
  src = fetchurl {
    url = "http://production.cf.rubygems.org/rubygems/rubygems-2.7.6.tgz";
    sha256 = "1sqy6z1kngq91nxmv1hw4xhw1ycwx9s76hfbpcdlgkm9haji9xv7";
  };
  patches = [
    (fetchpatch {
      url =
        "https://github.com/zimbatm/rubygems/compare/v2.6.6...v2.6.6-nix.patch";
      sha256 = "0297rdb1m6v75q8665ry9id1s74p9305dv32l95ssf198liaihhd";
    })
  ];
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
