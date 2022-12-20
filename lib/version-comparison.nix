# Usage:
# with (import version.nix) version;
# hasMajor 3 && lessThan "3.2"
# Examples:
# Apply patches only to 3.x, but the patch is already available from > 3.2
# hasMajor 3 && lessThan "3.2"
let
  inherit (builtins) compareVersions;
in
version:
rec {
  greatherThan = comparison: compareVersions version comparison > 0;
  lessThan = comparison: compareVersions version comparison < 0;
  equal = comparison: compareVersions version comparison == 0;
  notEqual = comparison: compareVersions version comparison != 0;
  greaterOrEqualTo = comparison: compareVersions version comparison >= 0;
  lessOrEqualTo = comparison: compareVersions version comparison <= 0;
  inRange = from: to: greaterOrEqualTo version from && lessOrEqualTo version to;
  hasMajor = major: greaterOrEqualTo "${major}" version && lessThan "${major + 1}" version;
  hasMajorMinor = major: minor: greaterOrEqualTo "${major}.${minor}" version && lessThan "${major}.${minor + 1}" version;
  hasMajorMinorPatch = major: minor: patch: greaterOrEqualTo "${major}.${minor}.${patch}" version && lessThan "${major}.${minor}.${patch + 1}" version;
}
