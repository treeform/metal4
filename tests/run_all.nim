## Compiles all examples first, then runs them sequentially.
## Close each window to proceed to the next example.

import
  std/[os, osproc, strformat]

const
  Examples = [
    "basic_screen",
    "basic_triangle",
    "basic_quad",
    "basic_cube",
    "sprite_sheet",
    "viewer_obj",
  ]

proc main() =
  let
    startDir = getCurrentDir()
    rootDir = currentSourcePath().parentDir.parentDir
  defer:
    setCurrentDir(startDir)

  echo "=== Metal4 Examples Runner ==="
  echo "Compiling all examples first."
  echo "Running all examples after successful compilation."
  echo "Close each window to proceed to the next example.\n"

  for i, name in Examples:
    let nimFile = "examples" / (name & ".nim")
    echo fmt"[{i + 1}/{Examples.len}] Compiling: {name}"

    setCurrentDir(rootDir)
    let exitCode = execCmd(fmt"nim c {nimFile}")
    if exitCode != 0:
      echo fmt"  ERROR: {name} failed to compile with exit code {exitCode}"
      quit(exitCode)
    echo ""

  echo "=== Compilation complete ===\n"

  for i, name in Examples:
    let binaryPath = "examples" / name
    echo fmt"[{i + 1}/{Examples.len}] Running: {name}"

    setCurrentDir(rootDir)
    let exitCode = execCmd(binaryPath)
    if exitCode != 0:
      echo fmt"  WARNING: {name} exited with code {exitCode}"
    echo ""

  echo "=== All examples completed ==="

when isMainModule:
  main()
