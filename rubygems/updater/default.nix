{ writeScriptBin, nodejs }:
writeScriptBin "update" ''
  ${nodejs}/bin/node ${./index.mjs}
''