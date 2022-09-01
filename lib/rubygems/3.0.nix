{
  stdenv,
  fetchurl,
  fetchpatch,
}:
stdenv.mkDerivation {
  pname = "rubygems";
  version = "3.2.33";
  src = fetchurl {
    url = "http://production.cf.rubygems.org/rubygems/rubygems-3.2.33.tgz";
    hash = "sha256-bIQIzS4F3IdwwxdmH0jVnNKcrLzRji8K7V1LqoibkC0=";
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
