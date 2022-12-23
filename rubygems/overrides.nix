{ versionComparison
, fetchpatch
}:
[
  {
    condition = version: with versionComparison version;
      lessThan "3.0.0";
    override = pkg: pkg.overrideAttrs (final: prev: {
      dontPatchShebangs = true;
      patches = prev.patches ++ [
        (fetchpatch {
          url = "https://github.com/zimbatm/rubygems/compare/v2.6.6...v2.6.6-nix.patch";
          sha256 = "0297rdb1m6v75q8665ry9id1s74p9305dv32l95ssf198liaihhd";
        })
      ];
    });
  }
  {
    condition = version: with versionComparison version;
      greaterOrEqualTo "3.0.0";
    override = pkg: pkg.overrideAttrs (final: prev: {
      patches = prev.patches ++ [
        (fetchpatch {
          url = "https://github.com/bobvanderlinden/rubygems/commit/0b5bcc8075deaedf692ac0d720ee03e0ca4dabc9.patch";
          hash = "sha256-8DZz1ycbkIC0Daz+dMJ8Olax8ZzQS0hWf7oIsiTfyvo=";
        })
      ];
    });
  }

]
