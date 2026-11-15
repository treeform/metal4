import metal4, windy/platforms/apple/objc as appleObjc

proc main() =
  ## Exercises Apple object messaging, struct ABI, and Metal queue completion.
  let pool = appleObjc.NSAutoreleasePool.new()
  defer: pool.release()

  let device = MTLCreateSystemDefaultDevice()
  checkNil(device, "A Metal device is required for the binding smoke test")
  defer: device.release()

  let queue = device.newCommandQueue()
  checkNil(queue, "Could not create the smoke test command queue")
  defer: queue.release()

  let layer = CAMetalLayer.alloc().init()
  checkNil(layer, "Could not create the smoke test drawable layer")
  defer: layer.release()
  layer.setDevice(device)
  layer.setPixelFormat(MTLPixelFormatBGRA8Unorm)
  layer.setDrawableSize(NSMakeSize(320.0, 640.0))
  let size = layer.drawableSize()
  doAssert size.width == 320.0 and size.height == 640.0

  let descriptor = MTLVertexDescriptor.alloc().init()
  checkNil(descriptor, "Could not create the smoke test vertex descriptor")
  defer: descriptor.release()
  let
    attribute = descriptor.attributes().objectAtIndexedSubscript(0)
    layout = descriptor.layouts().objectAtIndexedSubscript(0)
  attribute.setFormat(MTLVertexFormatFloat2)
  attribute.setOffset(8)
  attribute.setBufferIndex(0)
  layout.setStride(20)
  layout.setStepFunction(MTLVertexStepFunctionPerVertex)
  doAssert attribute.format() == MTLVertexFormatFloat2
  doAssert attribute.offset() == 8
  doAssert layout.stride() == 20

  let pipeline = MTLRenderPipelineDescriptor.alloc().init()
  checkNil(pipeline, "Could not create the smoke test pipeline descriptor")
  defer: pipeline.release()
  pipeline.setVertexDescriptor(descriptor)
  doAssert pipeline.vertexDescriptor().layouts()
    .objectAtIndexedSubscript(0).stride() == 20

  let
    pass = MTLRenderPassDescriptor.renderPassDescriptor()
    attachment = pass.colorAttachments().objectAtIndexedSubscript(0)
    color = MTLClearColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 1.0)
  attachment.setClearColor(color)
  doAssert attachment.clearColor() == color

  let command = queue.commandBuffer()
  checkNil(command, "Could not create the smoke test command buffer")
  command.retain()
  defer: command.release()
  command.commit()
  command.waitUntilCompleted()
  checkNSError(command.error(), "The smoke test command buffer failed")
  doAssert command.status() == MTLCommandBufferStatusCompleted
  echo "Apple binding ABI and Metal command queue smoke test passed."

main()
