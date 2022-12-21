# Usage:
# with (import version-comparison.nix) version;
# hasPrefix "3" && lessThan "3.2"
# Examples:
# Apply patch to problem only to 3.x, but problem was resolved in 3.2
# hasPrefix "3" && lessThan "3.2"
let
  inherit (builtins) compareVersions genList length elemAt all;
  hasPrefixList = prefix: list:
    let
      prefixLength = length prefix;
      listLength = length list;
      pairs = genList (n: { prefixItem = elemAt prefix n; listItem = elemAt list n;  }) prefixLength;
      pairsEqual = all ({ prefixItem, listItem }: prefixItem == listItem) pairs;
    in
      listLength >= prefixLength && pairsEqual;
in
version:
rec {
  greatherThan = comparison: compareVersions version comparison > 0;
  lessThan = comparison: compareVersions version comparison < 0;
  equal = comparison: compareVersions version comparison == 0;
  notEqual = comparison: compareVersions version comparison != 0;
  greaterOrEqualTo = comparison: compareVersions version comparison >= 0;
  lessOrEqualTo = comparison: compareVersions version comparison <= 0;
  inRange = from: to: greaterOrEqualTo from && lessOrEqualTo to;
  hasPrefix = prefix:
    let
      prefixSegments = builtins.splitVersion prefix;
      versionSegments = builtins.splitVersion version;
    in
      hasPrefixList prefixSegments versionSegments;
}
