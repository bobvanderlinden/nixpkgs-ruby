let
  isNumberString = str: (builtins.match "[[:digit:]]+" str) != null;
  parseInt = str: builtins.fromJSON str;
  tryParseInt = str: if isNumberString str then parseInt str else str;
in
{
  parseVersion = str: map tryParseInt (builtins.splitVersion str);
}