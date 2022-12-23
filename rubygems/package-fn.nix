{ version
, versionSource
, stdenv
, fetchurl
, fetchpatch
}:
stdenv.mkDerivation {
  pname = "rubygems";
  inherit version;
  src = fetchurl versionSource;

  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/cc1bb678f4205ad1c4db34c20b4327cb2cc89a93/pkgs/development/interpreters/ruby/rubygems/0001-add-post-extract-hook.patch";
      hash = "sha256-vC9D0iWJ+4HBhHZfivxLVjbwcYGA10P67cr9m6+WhaE=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/cc1bb678f4205ad1c4db34c20b4327cb2cc89a93/pkgs/development/interpreters/ruby/rubygems/0002-binaries-with-env-shebang.patch";
      hash = "sha256-TH5fMVdtwEFTDy6i3RjjkqViHwO3TExTs+Iqiok2KSc=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/cc1bb678f4205ad1c4db34c20b4327cb2cc89a93/pkgs/development/interpreters/ruby/rubygems/0003-gem-install-default-to-user.patch";
      hash = "sha256-WXDClowS398BKPnNm+fNf4OKVxlbYLLrVxVf1lL5v0A=";
    })
  ];

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
