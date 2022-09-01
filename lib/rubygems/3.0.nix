{
  stdenv,
  fetchurl,
  fetchpatch,
}:
stdenv.mkDerivation {
  pname = "rubygems";
  version = "3.2.13";
  src = fetchurl {
    url = "http://production.cf.rubygems.org/rubygems/rubygems-3.2.13.tgz";
    hash = "sha256-a4smZvBo26yjdtp5S3Z6myw32PMLCbYSkx/5OMhHFAM";
  };
  patches = [
    (fetchurl {
      url = "https://github.com/bobvanderlinden/rubygems/commit/0b5bcc8075deaedf692ac0d720ee03e0ca4dabc9.patch";
      hash = "sha256-hCHOGztZB67vB3hJ6lKdsgiUBw4SdhLQpFZbxKEOSjI=";
    })
  ];
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
