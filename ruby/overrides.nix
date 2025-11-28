{ versionComparison
, openssl_1_1
, stdenv
, fetchFromGitHub
}:
let
  opensslGem_3_1_2 = fetchFromGitHub {
    owner = "ruby";
    repo = "openssl";
    rev = "v3.1.2";
    hash = "sha256-LAVgwwZtYe4iIL2agdMeeNq0DzLu5x+AyvoKb95wFcU=";
  };
  opensslGem_3_2_2 = fetchFromGitHub {
    owner = "ruby";
    repo = "openssl";
    rev = "v3.2.2";
    hash = "sha256-q3e6JBauJ/j2ds2mR7mtjc00aS3o3yAncv+SPkafB9M=";
  };
  opensslGem_3_3_1 = fetchFromGitHub {
    owner = "ruby";
    repo = "openssl";
    rev = "v3.3.1";
    hash = "sha256-1QillscdCzY0hFtH0dcbiAiu4WZMV2XqiMBDZ/UMXZE=";
  };
in
[
  # Some of the older versions do not build.
  {
    condition = version: with versionComparison version;
      composeAny hasPrefix [
        "1"
        "2.0"
        "2.1.0-preview1"
        "2.1.0-preview2"
        "2.1.0-rc1"
        "2.2.0"
        "2.2.1"
        "2.2.2"
        "2.2.3"
        "2.2.4"
        "2.2.5"
        "2.2.6"
        "2.2.7"
        "2.2.8"
        "2.2.9"
        "2.2.10"
        "2.3.0"
        "2.3.1"
        "2.3.2"
        "2.3.3"
        "2.3.4"
        "2.3.5"
        "2.3.6"
        "2.3.7"
        "2.3.8"
        "2.4.0-preview1"
        "2.4.8"
        "2.5.2"
        "2.5.8"
        "2.6.7"
      ];
    override = pkg: pkg.overrideAttrs (finalAttrs: previousAttrs: { meta = previousAttrs.meta // { broken = true; }; });
  }
  # Some of the older versions do not build on OSX. Mark these as broken.
  {
    condition = version: stdenv.isDarwin && (with versionComparison version;
      composeAny hasPrefix [
        "2.1"
        "2.2.2"
        "2.2.3"
        "2.2.4"
        "2.2.5"
        "2.3.5"
        "2.3.6"
        "2.3.7"
        "2.3.8"
        "2.4.0"
        "2.4.1"
        "2.4.2"
        "2.4.3"
        "2.4.4"
        "2.4.5"
        "2.4.6"
        "2.4.7"
        "2.4.9"
        "2.4.10"
        "2.5.0"
        "2.5.1"
        "2.5.3"
        "2.5.4"
        "2.5.5"
        "2.5.6"
        "2.5.7"
        "2.5.9"
        "2.6.0"
        "2.6.1"
        "2.6.2"
        "2.6.3"
        "2.6.4"
        "2.6.5"
        "2.6.6"
        "2.7.0"
        "2.7.1"
        "3.0.0"
        "3.0.1"
        "3.0.2"
        "3.0.3"
        "3.0.4"
        "3.0.5"
        "3.0.6"
        "3.0.7"
        "3.1.0"
        "3.1.1"
        "3.1.2"
        "3.1.3"
      ]);
    override = pkg: pkg.overrideAttrs (finalAttrs: previousAttrs: { meta = previousAttrs.meta // { broken = true; }; });
  }
  # Ruby 3.1 introduced support for OpenSSL 3, everything before that uses OpenSSL 1.1.
  {
    condition = version: with versionComparison version;
      lessThan "3.1";
    override = pkg: pkg.override { openssl = openssl_1_1; };
  }
  # Ruby 3.1+ needs updated openssl gem versions for OpenSSL 3.6 support.
  # https://github.com/ruby/openssl/issues/949
  {
    condition = version: with versionComparison version;
      greaterOrEqualTo "3.1" && lessOrEqualTo "3.2.9";
    override = pkg: pkg.override { opensslGem = opensslGem_3_1_2; };
  }
  {
    condition = version: with versionComparison version;
      greaterOrEqualTo "3.3" && lessOrEqualTo "3.3.9";
    override = pkg: pkg.override { opensslGem = opensslGem_3_2_2; };
  }
  {
    condition = version: with versionComparison version;
      (greaterOrEqualTo "3.4" && lessOrEqualTo "3.4.7")
      || version == "3.5.0-preview1";
    override = pkg: pkg.override { opensslGem = opensslGem_3_3_1; };
  }
  # Ruby nowadays uses an convention for libDir = MAJOR.MINOR.0.
  # This wasn't the case for Ruby < 3.
  {
    condition = version: with versionComparison version;
      hasPrefix "2.0";
    override = pkg: pkg.override { libDir = "2.0.0"; };
  }
  {
    condition = version: with versionComparison version;
      hasPrefix "1.9" && greaterOrEqualTo "1.9.1";
    override = pkg: pkg.override { libDir = "1.9.1"; };
  }
  # yjit support was introduced in Ruby 3.2. Disable it for older versions.
  {
    condition = version: with versionComparison version;
      lessThan "3.2";
    override = pkg: pkg.override { yjitSupport = false; };
  }
]
