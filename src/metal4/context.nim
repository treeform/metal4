import
  windy,
  windy/platforms/macos/macdefs,
  codes, constants, types, functions, protocols, extras

type
  MetalContext* = object
    window*: Window
    device*: MTLDevice
    commandQueue*: MTLCommandQueue
    view*: NSView
    layer*: CAMetalLayer

proc updateDrawableSize*(ctx: var MetalContext) =
  ## Keeps the Metal drawable size in sync with the Windy window.
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
  ## Initializes a Metal 4 context for a Windy window.
  let resolvedDevice =
    if device.isNil:
      MTLCreateSystemDefaultDevice()
    else:
      device
  checkNil(resolvedDevice, "Could not create a Metal device")

  ctx.window = window
  ctx.device = resolvedDevice
  ctx.commandQueue = resolvedDevice.newCommandQueue()
  checkNil(ctx.commandQueue, "Could not create a Metal command queue")

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

  ctx.updateDrawableSize()

proc newMetalContext*(
  window: Window,
  device = 0.MTLDevice,
  pixelFormat: MTLPixelFormat = 80'u
): MetalContext =
  ## Creates a Metal 4 context for a Windy window.
  result.init(window, device, pixelFormat)

proc currentDrawable*(ctx: var MetalContext): CAMetalDrawable =
  ## Returns the current drawable after syncing the drawable size.
  ctx.updateDrawableSize()
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
