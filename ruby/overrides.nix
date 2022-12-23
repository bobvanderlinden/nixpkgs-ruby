{ versionComparison
, openssl_1_1
, rubygems-2_7
, rubygems-2_6
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
      (lessThan "3.0") || (hasPrefix "3.0" && lessThan "3.0.3");
    override = pkg: pkg.override { openssl = openssl_1_1; };
  }
  {
    condition = version: with versionComparison version;
      lessThan "2.5";
    override = pkg: pkg.override { rubygems = rubygems-2_7; };
  }
  {
    condition = version: with versionComparison version;
      lessOrEqualTo "2.4";
    override = pkg: pkg.override { rubygems = rubygems-2_6; };
  }
  {
    condition = version: with versionComparison version;
      hasPrefix "2.1";
    override = pkg: pkg.override { libDir = "2.0.0"; };
  }
  {
    condition = version: with versionComparison version;
      lessThan "2.0.0";
    override = pkg: pkg.override { libDir = pkg.version; };
  }
]
