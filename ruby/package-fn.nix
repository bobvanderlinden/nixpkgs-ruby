{ version
, versionSource
, libDir ? (import ./parse-version.nix version).libDir
, rubygems
, stdenv
, buildPackages
, lib
, fetchurl
, fetchpatch
, fetchFromSavannah
, fetchFromGitHub
, zlib
, openssl
, gdbm
, ncurses
, readline
, groff
, libyaml
, libffi
, bison
, autoconf
, darwin ? null
, buildEnv
, bundler
, bundix
, useRailsExpress ? true
, zlibSupport ? true
, opensslSupport ? true
, gdbmSupport ? true
, cursesSupport ? true
, docSupport ? false
, yamlSupport ? true
, fiddleSupport ? true
, yjitSupport ? true
, rustc
}:
let
  op = lib.optional;
  ops = lib.optionals;
  opString = lib.optionalString;
  config = import ./config.nix { inherit fetchFromSavannah; };
  versionString = version;

  # Needed during postInstall
  buildRuby =
    if stdenv.hostPlatform == stdenv.buildPlatform
    then "$out/bin/ruby"
    else "${buildPackages.ruby}/bin/ruby";

  self =
    stdenv.mkDerivation rec {
      pname = "ruby";
      version = import ./parse-version.nix versionString;

      patches = [ ];

      src = fetchurl versionSource;

      # Have `configure' avoid `/usr/bin/nroff' in non-chroot builds.
      NROFF =
        if docSupport
        then "${groff}/bin/nroff"
        else null;

      nativeBuildInputs =
        [ bison ]
        ++ ops (stdenv.buildPlatform != stdenv.hostPlatform)
          [ buildPackages.ruby ];
      buildInputs =
        (op fiddleSupport libffi)
        ++ (ops cursesSupport [ ncurses readline ])
        ++ (op docSupport groff)
        ++ (op zlibSupport zlib)
        ++ (op opensslSupport openssl)
        ++ (op gdbmSupport gdbm)
        ++ (op yamlSupport libyaml)
        ++ (op yjitSupport rustc)
        # Looks like ruby fails to build on darwin without readline even if curses
        # support is not enabled, so add readline to the build inputs if curses
        # support is disabled (if it's enabled, we already have it) and we're
        # running on darwin
        ++ (op (!cursesSupport && stdenv.isDarwin) readline)
        ++ (op stdenv.isDarwin darwin.apple_sdk.frameworks.Foundation)
        ++ (ops stdenv.isDarwin
          (with darwin; [ libiconv libobjc libunwind ]));

      enableParallelBuilding = true;

      postPatch = ''
        ${opString (rubygems != null) ''
          cp -rL --no-preserve=mode,ownership ${rubygems} ./rubygems
        ''}
        if [ -f configure.ac ]
        then
          sed -i configure.ac -e '/config.guess/d'
          cp ${config}/config.guess tool/
          cp ${config}/config.sub tool/
        fi
      '';

      preConfigure = ''
        sed -i configure -e 's/;; #(/\n;;/g'
      '';

      configureFlags =
        [ "--enable-shared" "--enable-pthread" ]
        ++ op (!docSupport) "--disable-install-doc"
        ++ ops stdenv.isDarwin [
          # on darwin, we have /usr/include/tk.h -- so the configure script detects
          # that tk is installed
          "--with-out-ext=tk"
          # on yosemite, "generating encdb.h" will hang for a very long time without this flag
          "--with-setjmp-type=setjmp"
        ];

      preInstall = ''
        # Ruby installs gems here itself now.
        mkdir -pv "$out/${passthru.gemPath}"
        export GEM_HOME="$out/${passthru.gemPath}"
      '';

      installFlags = lib.optionalString docSupport "install-doc";

      postInstall = ''
        ${opString (rubygems != null) ''
          # Update rubygems
          pushd rubygems
          ${buildRuby} setup.rb
          popd
        ''}
        # Remove unnecessary groff reference from runtime closure, since it's big
        sed -i '/NROFF/d' $out/lib/ruby/*/*/rbconfig.rb

        # Bundler tries to create this directory
        mkdir -p $out/nix-support
        cat > $out/nix-support/setup-hook <<EOF
        addGemPath() {
          addToSearchPath GEM_PATH \$1/${passthru.gemPath}
        }

        addEnvHooks "$hostOffset" addGemPath
        EOF
      '';

      meta = with lib; {
        description = "An object-oriented language for quick and easy programming";
        homepage = "http://www.ruby-lang.org/";
        license = licenses.ruby;
        maintainers = with maintainers; [ bobvanderlinden ];
        platforms = platforms.all;
      };

      passthru = rec {
        rubyEngine = "ruby";
        libPath = "lib/${rubyEngine}/${libDir}";
        gemPath = "lib/${rubyEngine}/gems/${libDir}";
        devEnv = import ./dev.nix {
          inherit buildEnv bundler bundix;
          ruby = self;
        };
      };
    };
in
self
