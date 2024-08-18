{ version
, versionSource
, libDir ? "${(import ./parse-version.nix version).majMin}.0"
, rubygems ? null
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
, removeReferencesTo
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
, jemallocSupport ? false
, jemalloc
}:
let
  op = lib.optional;
  ops = lib.optionals;
  opString = lib.optionalString;
  config = import ./config.nix { inherit fetchFromSavannah; };

  # Needed during postInstall
  buildRuby =
    if stdenv.hostPlatform == stdenv.buildPlatform
    then "$out/bin/ruby"
    else "${buildPackages.ruby}/bin/ruby";

  self =
    stdenv.mkDerivation {
      pname = "ruby";
      inherit version;

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
      propagatedBuildInputs =
        (op jemallocSupport jemalloc);

      enableParallelBuilding = true;

      postPatch = ''
        ${opString (rubygems != null) ''
          cp -rL --no-preserve=mode,ownership ${rubygems} ./rubygems
        ''}

        sed -i 's/\(:env_shebang *=> *\)false/\1true/' lib/rubygems/dependency_installer.rb
        sed -i 's/\(@home *=.* || \)Gem.default_dir/\1Gem.user_dir/' lib/rubygems/path_support.rb

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
        ++ op jemallocSupport "--with-jemalloc"
        ++ ops stdenv.isDarwin [
          # on darwin, we have /usr/include/tk.h -- so the configure script detects
          # that tk is installed
          "--with-out-ext=tk"
          # on yosemite, "generating encdb.h" will hang for a very long time without this flag
          "--with-setjmp-type=setjmp"
        ];

      preInstall = ''
        # Ruby installs gems here itself now.
        mkdir -pv "$out/${self.passthru.gemPath}"
        export GEM_HOME="$out/${self.passthru.gemPath}"
      '';

      installFlags = lib.optionalString docSupport "install-doc";

      postInstall = ''
        ${opString (rubygems != null) ''
          # Update rubygems
          pushd rubygems
          ${buildRuby} setup.rb
          popd
        ''}
        rbConfig=$(find $out/lib/ruby -name rbconfig.rb)

        # Remove references to the build environment from the closure
        sed -i '/^  CONFIG\["\(BASERUBY\|SHELL\|GREP\|EGREP\|MKDIR_P\|MAKEDIRS\|INSTALL\)"\]/d' $rbConfig

        # Remove unnecessary groff reference from runtime closure, since it's big
        sed -i '/NROFF/d' $rbConfig

        # Get rid of the CC runtime dependency
        ${removeReferencesTo}/bin/remove-references-to \
          -t ${stdenv.cc} \
          $out/lib/libruby*
        ${removeReferencesTo}/bin/remove-references-to \
          -t ${stdenv.cc} \
          $rbConfig
        sed -i '/CC_VERSION_MESSAGE/d' $rbConfig

        # Allow to override compiler. This is important for cross compiling as
        # we need to set a compiler that is different from the build one.
        sed -i 's/CONFIG\["CC"\] = "\(.*\)"/CONFIG["CC"] = if ENV["CC"].nil? || ENV["CC"].empty? then "\1" else ENV["CC"] end/'  "$rbConfig"

        # Remove unnecessary external intermediate files created by gems
        extMakefiles=$(find $out/${self.passthru.gemPath} -name Makefile)
        for makefile in $extMakefiles; do
          make -C "$(dirname "$makefile")" distclean
        done
        find "$out/${self.passthru.gemPath}" \( -name gem_make.out -o -name mkmf.log \) -delete

        # Bundler tries to create this directory
        mkdir -p $out/nix-support
        cat > $out/nix-support/setup-hook <<EOF
        addGemPath() {
          addToSearchPath GEM_PATH \$1/${self.passthru.gemPath}
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

      passthru = {
        version = {
          inherit libDir;
        } // (import ./parse-version.nix version);
        rubyEngine = "ruby";
        libPath = "lib/${self.passthru.rubyEngine}/${libDir}";
        gemPath = "lib/${self.passthru.rubyEngine}/gems/${libDir}";
        devEnv = import ./dev.nix {
          inherit buildEnv bundler bundix;
          ruby = self;
        };
      };
    };
in
self
