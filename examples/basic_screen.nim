import
  math,
  windy,
  metal4

const
  Width = 1280
  Height = 800

proc main() =
  ## Opens a Windy window and cycles the clear color.
  let window = newWindow(
    "Metal Color Cycle",
    ivec2(Width.int32, Height.int32)
  )

  let device = MTLCreateSystemDefaultDevice()
  checkNil(device, "Could not create a Metal device")

  let commandQueue = device.newCommandQueue()
  checkNil(commandQueue, "Could not create a Metal command queue")

  let view = window.nativeView

  let layer = CAMetalLayer.alloc().init()
  checkNil(layer, "Could not create a CAMetalLayer")
  layer.setDevice(device)
  layer.setPixelFormat(MTLPixelFormatBGRA8Unorm)
  layer.setFramebufferOnly(true)
  layer.setOpaque(true)

  view.setWantsLayer(true)
  let hostLayer = view.layer()
  checkNil(hostLayer, "Could not acquire the host CALayer")
  hostLayer.addSublayer(layer)

  var
    timeAcc = 0.0

  while not window.closeRequested:
    pollEvents()
    timeAcc += 0.016

    let
      r = sin(timeAcc * 0.6) * 0.5 + 0.5
      g = sin(timeAcc * 0.6 + 2.094) * 0.5 + 0.5
      b = sin(timeAcc * 0.6 + 4.188) * 0.5 + 0.5
      bounds = view.bounds
      backing = view.convertRectToBacking(bounds)

    layer.setFrame(bounds)
    layer.setContentsScale(window.contentScale.float64)
    layer.setDrawableSize(
      NSMakeSize(backing.size.width, backing.size.height)
    )

    let drawable = layer.nextDrawable()

    if drawable.isNil:
      continue

    let commandBuffer = commandQueue.commandBuffer()
    checkNil(commandBuffer, "Could not create a Metal command buffer")

    let renderPass = MTLRenderPassDescriptor.renderPassDescriptor()
    let colorAttachment =
      renderPass.colorAttachments().objectAtIndexedSubscript(0)
    colorAttachment.setTexture(drawable.texture())
    colorAttachment.setLoadAction(MTLLoadActionClear)
    colorAttachment.setStoreAction(MTLStoreActionStore)
    colorAttachment.setClearColor(
      MTLClearColor(red: r, green: g, blue: b, alpha: 1.0)
    )

    let encoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPass)
    checkNil(encoder, "Could not create a Metal render encoder")
    encoder.setViewport(
      MTLViewport(
        originX: 0,
        originY: 0,
        width: backing.size.width,
        height: backing.size.height,
        znear: 0,
        zfar: 1
      )
    )

    encoder.endEncoding()
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()

main()
