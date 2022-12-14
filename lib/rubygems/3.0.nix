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
  patches = [ ./3.0.patch ];
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
