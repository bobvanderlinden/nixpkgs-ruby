{ versionComparison
, fetchpatch
, fetchurl
}:
[
  {
    condition = version: with versionComparison version;
      lessThan "3.0.0";
    override = pkg: pkg.overrideAttrs (final: prev: {
      dontPatchShebangs = true;
      patches = [
        (fetchpatch {
          url = "https://github.com/zimbatm/rubygems/compare/v2.6.6...v2.6.6-nix.patch";
          sha256 = "0297rdb1m6v75q8665ry9id1s74p9305dv32l95ssf198liaihhd";
        })
      ];
    });
  }
]
