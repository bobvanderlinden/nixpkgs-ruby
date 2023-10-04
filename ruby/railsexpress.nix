{ fetchFromGitHub, lib, version }:

let
  firstSupportedRubyVersion = "2.7.6";

  rvmPatchsets = fetchFromGitHub {
    owner = "skaes";
    repo = "rvm-patchsets";
    rev = "d1e981c193da981e3300cdcc2d50b4a97df5d759";
    sha256 = "1zhk7y66gsijyjm9gkcbcdfk44mj8yrvwqv0h3b72b6yxfkhx8z2";
  };

  dirFilter = n: v: ((v == "directory") &&
    ((builtins.match "^[0-9]\\.[0-9]\\.[0-9]+$" n) != null) &&
    (lib.versionAtLeast n firstSupportedRubyVersion));

  rubyIndex = lib.mapAttrsToList
    (n: v: n)
    (lib.filterAttrs
      dirFilter
      (builtins.readDir "${rvmPatchsets}/patchsets/ruby/"));

  indexFileRawLines = rubyVersion:
    lib.splitString
      "\n"
      (lib.readFile ("${rvmPatchsets}/patchsets/ruby/" +
        "${rubyVersion}/railsexpress"));

  removeEmptyLines = line: line != "";

  indexFileLines = rubyVersion:
    lib.filter
      removeEmptyLines
      (indexFileRawLines rubyVersion);

  versionPatches = rubyVersion: indexFileLines:
    map
      (p: "${rvmPatchsets}/patches/ruby/${rubyVersion}/${p}")
      indexFileLines;

  indexToPatches = rubyVersion:
    {
      name = rubyVersion;
      value = (versionPatches rubyVersion
        (indexFileLines rubyVersion));
    };

  patchSets = builtins.listToAttrs (map (i: indexToPatches i) rubyIndex);
in

if builtins.hasAttr version patchSets then patchSets."${version}" else [ ]
