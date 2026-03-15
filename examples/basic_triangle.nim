import
  windy,
  metal4

const
  ShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  float4 position [[position]];
  float4 color;
};

vertex VertexOut vertexMain(uint vertexId [[vertex_id]]) {
  const float2 positions[3] = {
    float2(0.0, 0.72),
    float2(-0.72, -0.62),
    float2(0.72, -0.62)
  };
  const float3 colors[3] = {
    float3(1.0, 0.25, 0.25),
    float3(0.25, 1.0, 0.35),
    float3(0.25, 0.45, 1.0)
  };

  VertexOut out;
  out.position = float4(positions[vertexId], 0.0, 1.0);
  out.color = float4(colors[vertexId], 1.0);
  return out;
}

fragment float4 fragmentMain(VertexOut in [[stage_in]]) {
  return in.color;
}
"""

proc main() =
  ## Opens a Windy window and draws a Metal triangle.
  let window = newWindow("Metal Triangle", ivec2(960, 640))

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

  var error: NSError
  let library = device.newLibraryWithSource(@ShaderSource, 0.ID, error.addr)
  checkNSError(error, "Could not compile Metal shaders")
  checkNil(library, "Metal shader library was nil")

  let vertexFunction = library.newFunctionWithName(@"vertexMain")
  checkNil(vertexFunction, "Could not load Metal shader entry point: vertexMain")

  let fragmentFunction = library.newFunctionWithName(@"fragmentMain")
  checkNil(
    fragmentFunction,
    "Could not load Metal shader entry point: fragmentMain"
  )

  let descriptor = MTLRenderPipelineDescriptor.alloc().init()
  checkNil(descriptor, "Could not create a pipeline descriptor")
  let colorAttachment = descriptor.colorAttachments().objectAtIndexedSubscript(0)
  descriptor.setVertexFunction(vertexFunction)
  descriptor.setFragmentFunction(fragmentFunction)
  colorAttachment.setPixelFormat(MTLPixelFormatBGRA8Unorm)

  error = 0.NSError
  let pipelineState =
    device.newRenderPipelineStateWithDescriptor(descriptor, error.addr)
  checkNSError(error, "Could not create Metal pipeline")
  checkNil(pipelineState, "Metal pipeline state was nil")

  while not window.closeRequested:
    let
      bounds = view.bounds
      backing = view.convertRectToBacking(bounds)
    layer.setFrame(bounds)
    layer.setContentsScale(window.contentScale.float64)
    layer.setDrawableSize(
      NSMakeSize(backing.size.width, backing.size.height)
    )

    let drawable = layer.nextDrawable()
    if drawable.isNil:
      pollEvents()
      continue

    let commandBuffer = commandQueue.commandBuffer()
    checkNil(commandBuffer, "Could not create a Metal command buffer")

    let renderPass = MTLRenderPassDescriptor.renderPassDescriptor()
    let renderAttachment =
      renderPass.colorAttachments().objectAtIndexedSubscript(0)
    renderAttachment.setTexture(drawable.texture())
    renderAttachment.setLoadAction(MTLLoadActionClear)
    renderAttachment.setStoreAction(MTLStoreActionStore)
    renderAttachment.setClearColor(
      MTLClearColor(
        red: 0.08,
        green: 0.09,
        blue: 0.12,
        alpha: 1.0
      )
    )

    let encoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPass)
    checkNil(encoder, "Could not create a Metal render encoder")
    encoder.setRenderPipelineState(pipelineState)
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

    encoder.drawPrimitives(MTLPrimitiveTypeTriangle, 0, 3)
    encoder.endEncoding()
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()

    pollEvents()

main()
