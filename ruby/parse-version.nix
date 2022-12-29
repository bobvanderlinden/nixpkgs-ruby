version:
let
  versionSegments = builtins.splitVersion version ++ [ "" "" "" ];
  versionComparison = import ../lib/version-comparison.nix;
  versionAtLeast = lhs: rhs: (versionComparison lhs).greaterOrEqualTo(rhs);
in
rec {
  inherit version;
  major = builtins.elemAt versionSegments 0;
  minor = builtins.elemAt versionSegments 1;
  tiny = builtins.elemAt versionSegments 2;
  tail = builtins.elemAt versionSegments 3;

  # Ruby separates lib and gem folders by ABI version which isn't very
  # consistent.
  libDir =
    if versionAtLeast majMinTiny "2.1.0" then
      "${majMin}.0"
    else if versionAtLeast majMinTiny "2.0.0" then
      "2.0.0"
    else if versionAtLeast majMinTiny "1.9.1" then
      "1.9.1"
    else
      throw "version ${majMinTiny} is not supported";

  # Shortcuts
  majMin = "${major}.${minor}";
  majMinTiny = "${major}.${minor}.${tiny}";

  # Implements the builtins.toString interface.
  __toString = self: self.version;
}
