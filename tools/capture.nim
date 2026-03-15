## Captures a screenshot of a running example on macOS.
## Usage: nim r tools/capture.nim <exe_path> [delay_seconds] [output_png]
##
## Launches the executable, waits for its window to appear,
## waits the specified delay (default 3s), takes a screenshot,
## saves it as PNG via `screencapture`, then kills the process.
##
## Notes:
## - macOS may require Accessibility permission for `osascript`.
## - macOS may require Screen Recording permission for `screencapture`.

when not defined(macosx):
  {.error: "capture.nim only runs on macOS.".}

import
  std/[os, osproc, streams, strformat, strutils, times]

type
  CaptureError = object of CatchableError

proc runCommand(command: string, args: openArray[string]): tuple[
  exitCode: int,
  output: string
] =
  ## Runs a subprocess and captures its combined output.
  let process = startProcess(
    command,
    args = args,
    options = {poUsePath, poStdErrToStdOut}
  )
  defer:
    process.close()

  let output = process.outputStream.readAll()
  let exitCode = waitForExit(process)
  (exitCode, output)

proc runAppleScript(lines: openArray[string]): string =
  ## Runs an AppleScript snippet and returns trimmed output.
  var args: seq[string]
  for line in lines:
    args.add("-e")
    args.add(line)

  let (exitCode, output) = runCommand("osascript", args)
  if exitCode != 0:
    raise newException(
      CaptureError,
      "AppleScript failed: " & output.strip()
    )
  output.strip()

proc windowRect(pid: int): string =
  ## Returns `x,y,width,height` for the front window of a process.
  runAppleScript([
    "tell application \"System Events\"",
    "  set targetProcess to first process whose unix id is " & $pid,
    "  if (count of windows of targetProcess) is 0 then",
    "    return \"\"",
    "  end if",
    "  set frontmost of targetProcess to true",
    "  tell window 1 of targetProcess",
    "    set p to position",
    "    set s to size",
    "    return (item 1 of p as string) & \",\" & " &
      "(item 2 of p as string) & \",\" & " &
      "(item 1 of s as string) & \",\" & " &
      "(item 2 of s as string)",
    "  end tell",
    "end tell"
  ])

proc parseRect(text: string): tuple[x, y, width, height: int] =
  ## Parses `x,y,width,height` output from AppleScript.
  let parts = text.split(",")
  if parts.len != 4:
    raise newException(CaptureError, "Invalid window rect: " & text)
  result.x = parseInt(parts[0].strip())
  result.y = parseInt(parts[1].strip())
  result.width = parseInt(parts[2].strip())
  result.height = parseInt(parts[3].strip())

proc activateWindow(pid: int) =
  ## Brings the target process to the front.
  discard runAppleScript([
    "tell application \"System Events\"",
    "  set frontmost of (first process whose unix id is " & $pid & ") to true",
    "end tell"
  ])

proc captureRect(x, y, width, height: int, outputPng: string) =
  ## Captures a rectangle to a PNG file using `screencapture`.
  let (exitCode, output) = runCommand(
    "screencapture",
    [
      "-x",
      "-R",
      &"{x},{y},{width},{height}",
      outputPng
    ]
  )
  if exitCode != 0:
    raise newException(
      CaptureError,
      "screencapture failed: " & output.strip()
    )

proc main() =
  let args = commandLineParams()
  if args.len < 1:
    echo "Usage: capture <exe_path> [delay_seconds] [output_png]"
    echo "  exe_path        Path to the executable to run"
    echo "  delay_seconds   Seconds to wait before screenshot (default: 3)"
    echo "  output_png      Output PNG path (default: <exe_name>.png in docs/)"
    quit(1)

  let
    exePath = absolutePath(args[0])
    delaySec = if args.len >= 2: parseInt(args[1]) else: 3
    scriptDir = parentDir(currentSourcePath())
    docsDir = normalizedPath(scriptDir / ".." / "docs")
    defaultPng = docsDir / (exePath.splitFile().name & ".png")
    outputPng = if args.len >= 3: args[2] else: defaultPng

  if not fileExists(exePath):
    echo &"ERROR: Executable not found: {exePath}"
    quit(1)

  createDir(parentDir(outputPng))

  echo &"Launching: {exePath}"
  let process = startProcess(
    exePath,
    workingDir = parentDir(exePath)
  )
  defer:
    process.close()

  let pid = processID(process)
  echo &"  PID: {pid}"

  echo "Waiting for window..."
  var
    rectText = ""
    lastError = ""
  let deadline = getTime() + initDuration(seconds = 15)
  while getTime() < deadline:
    if not process.running():
      break
    try:
      rectText = windowRect(pid)
      if rectText.len > 0:
        break
    except CaptureError as err:
      lastError = err.msg
    sleep(250)

  if rectText.len == 0:
    process.kill()
    if not process.running():
      echo &"ERROR: Process exited before a window was found."
      echo &"  Exit code: {process.peekExitCode()}"
    elif lastError.len > 0:
      echo &"ERROR: {lastError}"
      echo "Hint: Check Accessibility permission for Terminal/Cursor."
    else:
      echo "ERROR: No window found within 15 seconds"
      echo "Hint: Check Accessibility permission for Terminal/Cursor."
    quit(1)

  activateWindow(pid)
  echo &"Window found. Waiting {delaySec}s for content to render..."
  sleep(delaySec * 1000)

  let rect = parseRect(rectText)
  echo &"  Window size: {rect.width}x{rect.height} at ({rect.x}, {rect.y})"

  if rect.width <= 0 or rect.height <= 0:
    process.kill()
    echo "ERROR: Invalid window dimensions"
    quit(1)

  captureRect(rect.x, rect.y, rect.width, rect.height, outputPng)
  echo &"  Saved: {outputPng}"

  process.kill()
  echo "Done."

when isMainModule:
  main()
