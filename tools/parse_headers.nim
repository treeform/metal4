import
  std/[json, os]

import metal4_ir, metal4_parser

proc main() =
  ## Parses vendored headers and writes a JSON IR snapshot.
  let
    root = currentSourcePath.parentDir / ".."
    headersRoot = root / "headers"
    outputPath = headersRoot / "ir.json"
    ir = parseHeaders(headersRoot)

  writeFile(outputPath, ir.toJson().pretty() & "\n")

  echo "Parsed headers:"
  echo "  enums:      " & $ir.enums.len
  echo "  structs:    " & $ir.structs.len
  echo "  handles:    " & $ir.handles.len
  echo "  aliases:    " & $ir.aliases.len
  echo "  properties: " & $ir.properties.len
  echo "  methods:    " & $ir.methods.len
  echo "  functions:  " & $ir.functions.len

when isMainModule:
  main()
