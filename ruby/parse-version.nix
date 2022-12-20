version:
let
  versionSegments = builtins.splitVersion version ++ [ "" "" "" ];
in
rec {
  inherit version;
  major = builtins.elemAt versionSegments 0;
  minor = builtins.elemAt versionSegments 1;
  tiny = builtins.elemAt versionSegments 2;
  tail = builtins.elemAt versionSegments 3;

  # Shortcuts
  majMin = "${major}.${minor}";
  majMinTiny = "${major}.${minor}.${tiny}";

  # Implements the builtins.toString interface.
  __toString = self: self.version;
}
