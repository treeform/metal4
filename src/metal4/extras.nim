import
  windy/platforms/macos/[macdefs, objc],
  constants, types, protocols

objc:
  proc setWantsLayer*(self: NSView, x: bool)
  proc layer*(self: NSView): CALayer
  proc setLayer*(self: NSView, x: CALayer)
  proc addSublayer*(self: CALayer, x: CALayer)
  proc setFrame*(self: CALayer, x: NSRect)
  proc setContentsScale*(self: CALayer, x: float64)
  proc setOpaque*(self: CALayer, x: bool)
