import foundations, constants, types, protocols

when defined(ios):
  {.passL: "-framework MetalKit".}

  type MTKView* = distinct NSObject

  objc:
    proc device*(self: MTKView): MTLDevice
    proc layer*(self: MTKView): CAMetalLayer
    proc currentDrawable*(self: MTKView): CAMetalDrawable
    proc drawableSize*(self: MTKView): NSSize
    proc colorPixelFormat*(self: MTKView): MTLPixelFormat
    proc setColorPixelFormat*(self: MTKView, x: MTLPixelFormat)
else:
  objc:
    proc setWantsLayer*(self: NSView, x: bool)
    proc layer*(self: NSView): CALayer
    proc setLayer*(self: NSView, x: CALayer)

objc:
  proc addSublayer*(self: CALayer, x: CALayer)
  proc removeFromSuperlayer*(self: CALayer)
  proc setFrame*(self: CALayer, x: NSRect)
  proc setContentsScale*(self: CALayer, x: float64)
  proc setOpaque*(self: CALayer, x: bool)
