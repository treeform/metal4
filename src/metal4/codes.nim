when not defined(macosx):
  {.error: "metal4 only runs on macOS.".}

import
  windy/platforms/macos/[macdefs, objc]

type
  Metal4Error* = object of CatchableError

proc isNil*[T](value: T): bool =
  ## Returns true when an Objective-C handle is nil.
  cast[uint](value) == 0'u

proc messageNSError*(error: NSError, msg: string): string =
  ## Returns a readable error message for an NSError value.
  if error.isNil:
    result = msg
  else:
    result = msg & ": " & $error

proc checkNSError*(error: NSError, msg: string) =
  ## Raises Metal4Error when NSError is present.
  if not error.isNil:
    raise newException(Metal4Error, messageNSError(error, msg))

proc checkNil*[T](value: T, msg: string) =
  ## Raises Metal4Error when an Objective-C handle is nil.
  if value.isNil:
    raise newException(Metal4Error, msg)
