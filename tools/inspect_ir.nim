import
  std/os

import metal4_parser

proc main() =
  ## Prints a compact summary of the parsed vendored headers.
  let
    root = currentSourcePath.parentDir / ".."
    headersRoot = root / "headers"
    ir = parseHeaders(headersRoot)

  echo "Enums:"
  for item in ir.enums:
    echo "  ", item.name, " (", item.values.len, " values)"

  echo ""
  echo "Structs:"
  for item in ir.structs:
    echo "  ", item.name, " (", item.fields.len, " fields)"

  echo ""
  echo "Handles:"
  for item in ir.handles:
    echo "  ", item.kind, " ", item.name, " : ", item.baseName

when isMainModule:
  main()
