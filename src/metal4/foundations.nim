when defined(ios):
  import windy/platforms/apple/objc
  export objc

  {.passL: "-framework Foundation -framework CoreGraphics".}

  type
    NSObject* = distinct int
    CGPoint* {.pure, bycopy.} = object
      x*, y*: float64
    CGSize* {.pure, bycopy.} = object
      width*, height*: float64
    CGRect* {.pure, bycopy.} = object
      origin*: CGPoint
      size*: CGSize
    NSPoint* = CGPoint
    NSSize* = CGSize
    NSRect* = CGRect

  proc NSMakeSize*(width, height: float64): NSSize =
    ## Creates a CoreGraphics size using CGFloat's 64-bit Apple ABI.
    NSSize(width: width, height: height)

  objc:
    proc retain*(self: ID)
    proc release*(self: ID)
else:
  import windy/platforms/macos/macdefs
  export macdefs

proc retain*[T](value: T) =
  ## Retains an Objective-C handle beyond the current autorelease pool.
  retain(cast[ID](value))

proc release*[T](value: T) =
  ## Releases an owned Objective-C handle; a nil handle is safe.
  release(cast[ID](value))
