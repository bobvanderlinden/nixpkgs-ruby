{ fetchFromGitHub, lib, version }:

let
  firstSupportedRubyVersion = "2.7.6";

  rvmPatchsets = fetchFromGitHub {
    owner = "skaes";
    repo = "rvm-patchsets";
    rev = "e6574c54a34fe6e4d45aa1433872a22ddfe14cf3";
    sha256 = "x2KvhgRVJ4Nc5v1j4DggKO1u3otG8HVMxhq4yuUKnds=";
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
