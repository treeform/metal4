import
  windy,
  foundations, codes, constants, types, functions, protocols, extras

type
  MetalContext* = object
    ## Owns its command queue; destroy it after outstanding GPU work completes.
    window*: Window
    device*: MTLDevice
    commandQueue*: MTLCommandQueue
    when defined(ios):
      view*: MTKView
    else:
      view*: NSView
    layer*: CAMetalLayer
    ownsDevice: bool
    pixelFormat: MTLPixelFormat

proc `=copy`*(dest: var MetalContext, source: MetalContext) {.error:
  "MetalContext owns native resources; move it instead of copying it".}
  ## Prevents two contexts from releasing the same native resources.

proc destroy*(ctx: var MetalContext) =
  ## Releases context-owned resources after its GPU work has completed.
  ## Call once for each initialized context; its native handles are not copied.
  ctx.commandQueue.release()
  when not defined(ios):
    ctx.layer.removeFromSuperlayer()
    ctx.layer.release()
  if ctx.ownsDevice:
    ctx.device.release()
  ctx = default(MetalContext)

proc updateDrawableSize*(ctx: var MetalContext) =
  ## Keeps the Metal drawable size in sync with the Windy window.
  when defined(ios):
    # MTKView owns drawable sizing, including scale and orientation changes.
    # Refresh borrowed handles after Windy's surface has been recreated.
    ctx.view = cast[MTKView](ctx.window.metalView())
    if ctx.view.isNil:
      ctx.layer = 0.CAMetalLayer
      return
    if cast[int](ctx.view.device()) != cast[int](ctx.device):
      raise newException(Metal4Error, "The Windy Metal device has changed")
    if ctx.view.colorPixelFormat() != ctx.pixelFormat:
      ctx.view.setColorPixelFormat(ctx.pixelFormat)
    ctx.layer = ctx.view.layer()
  else:
    let
      bounds = ctx.view.bounds
      backing = ctx.view.convertRectToBacking(bounds)

    ctx.layer.setFrame(bounds)
    ctx.layer.setContentsScale(ctx.window.contentScale.float64)
    ctx.layer.setDrawableSize(
      NSMakeSize(backing.size.width, backing.size.height)
    )

proc init*(
  ctx: var MetalContext,
  window: Window,
  device = 0.MTLDevice,
  pixelFormat: MTLPixelFormat = 80'u
) =
  ## Initializes a Metal context, after surface creation on iOS.
  if not ctx.commandQueue.isNil:
    raise newException(Metal4Error, "The Metal context is already initialized")
  if window.isNil:
    raise newException(Metal4Error, "A Metal context requires a Windy window")
  try:
    ctx.window = window
    ctx.pixelFormat = pixelFormat
    when defined(ios):
      ctx.view = cast[MTKView](window.metalView())
      checkNil(ctx.view, "The Windy Metal surface is not ready")
      ctx.device = ctx.view.device()
      checkNil(ctx.device, "The Windy Metal view has no device")
      if not device.isNil and cast[int](device) != cast[int](ctx.device):
        raise newException(
          Metal4Error,
          "The Metal context must use the Windy Metal view's device"
        )
      ctx.layer = ctx.view.layer()
      checkNil(ctx.layer, "The Windy Metal view has no drawable layer")
      ctx.view.setColorPixelFormat(pixelFormat)
    else:
      ctx.device =
        if device.isNil:
          MTLCreateSystemDefaultDevice()
        else:
          device
      ctx.ownsDevice = device.isNil
      checkNil(ctx.device, "Could not create a Metal device")
      ctx.view = window.nativeView
      ctx.layer = CAMetalLayer.alloc().init()
      checkNil(ctx.layer, "Could not create a CAMetalLayer")
      ctx.layer.setDevice(ctx.device)
      ctx.layer.setPixelFormat(pixelFormat)
      ctx.layer.setFramebufferOnly(true)
      ctx.layer.setOpaque(true)
      ctx.view.setWantsLayer(true)
      let hostLayer = ctx.view.layer()
      checkNil(hostLayer, "Could not acquire the host CALayer")
      hostLayer.addSublayer(ctx.layer)

    ctx.commandQueue = ctx.device.newCommandQueue()
    checkNil(ctx.commandQueue, "Could not create a Metal command queue")
    ctx.updateDrawableSize()
  except:
    ctx.destroy()
    raise

proc newMetalContext*(
  window: Window,
  device = 0.MTLDevice,
  pixelFormat: MTLPixelFormat = 80'u
): MetalContext =
  ## Creates a Metal context for a Windy window, ready to draw on iOS.
  result.init(window, device, pixelFormat)

proc currentDrawable*(ctx: var MetalContext): CAMetalDrawable =
  ## Borrows this frame's drawable, or nil while no surface is available.
  ctx.updateDrawableSize()
  when defined(ios):
    result = ctx.view.currentDrawable()
  else:
    result = ctx.layer.nextDrawable()

proc newCommandBuffer*(ctx: MetalContext): MTLCommandBuffer =
  ## Creates a command buffer from the context queue.
  result = ctx.commandQueue.commandBuffer()
  checkNil(result, "Could not create a Metal command buffer")

proc clearPass*(
  ctx: var MetalContext,
  drawable: CAMetalDrawable,
  clear: MTLClearColor
): MTLRenderPassDescriptor =
  ## Creates a clear pass descriptor for the current drawable.
  ctx.updateDrawableSize()

  let
    descriptor = MTLRenderPassDescriptor.renderPassDescriptor()
    colorAttachment =
      descriptor.colorAttachments().objectAtIndexedSubscript(0)

  colorAttachment.setTexture(drawable.texture())
  colorAttachment.setLoadAction(MTLLoadActionClear)
  colorAttachment.setStoreAction(MTLStoreActionStore)
  colorAttachment.setClearColor(clear)
  result = descriptor
