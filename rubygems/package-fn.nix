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
      hash = "sha256-kHGcrBMTwixCs06mCPnpv3B3mVseT08izzJ8F7b3u+M=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/cc1bb678f4205ad1c4db34c20b4327cb2cc89a93/pkgs/development/interpreters/ruby/rubygems/0002-binaries-with-env-shebang.patch";
      hash = "sha256-DQVwqCRqkjtXNKcUi/363reFUgFsTOb328da3xGnfcY=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/cc1bb678f4205ad1c4db34c20b4327cb2cc89a93/pkgs/development/interpreters/ruby/rubygems/0003-gem-install-default-to-user.patch";
      hash = "sha256-8XR1FZ6LFgoNXl/65eeFGmJ8EeJUsVFmELHDAJxS61Q=";
    })
  ];

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
