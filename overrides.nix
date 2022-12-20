{ versionComparison
, openssl_1_1
}:
[
  {
    condition = version: with versionComparison version;
      lessThan "3";
    override = pkg: pkg.override { openssl = openssl_1_1; };
  }
]
