{ versionComparison
, openssl_1_1
}:
[
  {
    condition = version: with versionComparison version;
      composeAny hasPrefix [
        "1"
        "2.0"
        "2.1.0-preview1"
        "2.1.0-preview2"
        "2.1.0-rc1"
        "2.2.0"
        "2.2.10"
        "2.3.0"
        "2.3.2"
        "2.3.3"
        "2.4.0-preview1"
        "2.4.8"
        "2.5.2"
        "2.5.8"
      ];
    override = pkg: pkg.overrideAttrs (finalAttrs: previousAttrs: { meta = previousAttrs.meta // { broken = true; }; });
  }
  {
    condition = version: with versionComparison version;
      lessThan "3.0.3";
    override = pkg: pkg.override { openssl = openssl_1_1; };
  }
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
  {
    condition = version: with versionComparison version;
      lessThan "3.2";
    override = pkg: pkg.override { yjitSupport = false; };
  }
  {
    condition = version: with versionComparison version;
      lessThan "2.7.6";
    override = pkg: pkg.override { useRailsExpress = false; };
  }
]
