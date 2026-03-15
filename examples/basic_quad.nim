import
  std/os,
  pixie,
  windy,
  windy/platforms/macos/[macdefs, objc],
  metal4

type
  QuadRenderer = object
    pipelineState: MTLRenderPipelineState
    texture: MTLTexture
    sampler: MTLSamplerState

const
  Width = 1280
  Height = 800
  Clear = MTLClearColor(
    red: 0.05,
    green: 0.05,
    blue: 0.1,
    alpha: 1.0
  )
  ShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  float4 position [[position]];
  float2 uv;
};

vertex VertexOut vertexMain(uint vertexId [[vertex_id]]) {
  const float2 positions[6] = {
    float2(-0.5,  0.5),
    float2( 0.5,  0.5),
    float2( 0.5, -0.5),
    float2(-0.5,  0.5),
    float2( 0.5, -0.5),
    float2(-0.5, -0.5)
  };
  const float2 uvs[6] = {
    float2(0.0, 0.0),
    float2(1.0, 0.0),
    float2(1.0, 1.0),
    float2(0.0, 0.0),
    float2(1.0, 1.0),
    float2(0.0, 1.0)
  };

  VertexOut out;
  out.position = float4(positions[vertexId], 0.0, 1.0);
  out.uv = uvs[vertexId];
  return out;
}

fragment float4 fragmentMain(
  VertexOut in [[stage_in]],
  texture2d<float> tex [[texture(0)]],
  sampler texSampler [[sampler(0)]]
) {
  return tex.sample(texSampler, in.uv);
}
"""

proc texturePath(): string =
  ## Returns the local path to the example texture.
  currentSourcePath.parentDir / "testTexture.png"

proc loadTexture(device: MTLDevice): MTLTexture =
  ## Loads the example texture into a Metal texture.
  let image = readImage(texturePath())

  let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatRGBA8Unorm,
    image.width.uint,
    image.height.uint,
    false
  )
  result = device.newTextureWithDescriptor(descriptor)
  checkNil(result, "Could not create a Metal texture")

  result.replaceRegion(
    MTLRegion(
      origin: MTLOrigin(x: 0, y: 0, z: 0),
      size: MTLSize(
        width: image.width.uint,
        height: image.height.uint,
        depth: 1
      )
    ),
    0,
    unsafeAddr image.data[0],
    (image.width * 4).uint
  )

proc initRenderer(device: MTLDevice, renderer: var QuadRenderer) =
  ## Compiles the shaders and creates the quad pipeline.
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

  let pipelineDescriptor = MTLRenderPipelineDescriptor.alloc().init()
  checkNil(pipelineDescriptor, "Could not create a pipeline descriptor")
  let colorAttachment =
    pipelineDescriptor.colorAttachments().objectAtIndexedSubscript(0)
  pipelineDescriptor.setVertexFunction(vertexFunction)
  pipelineDescriptor.setFragmentFunction(fragmentFunction)
  colorAttachment.setPixelFormat(MTLPixelFormatBGRA8Unorm)

  error = 0.NSError
  renderer.pipelineState = device.newRenderPipelineStateWithDescriptor(
    pipelineDescriptor,
    error.addr
  )
  checkNSError(error, "Could not create Metal pipeline")
  checkNil(renderer.pipelineState, "Metal pipeline state was nil")

  renderer.texture = loadTexture(device)

  let samplerDescriptor = MTLSamplerDescriptor.alloc().init()
  checkNil(samplerDescriptor, "Could not create a Metal sampler descriptor")
  samplerDescriptor.setMinFilter(MTLSamplerMinMagFilterLinear)
  samplerDescriptor.setMagFilter(MTLSamplerMinMagFilterLinear)
  samplerDescriptor.setSAddressMode(MTLSamplerAddressModeRepeat)
  samplerDescriptor.setTAddressMode(MTLSamplerAddressModeRepeat)
  renderer.sampler = device.newSamplerStateWithDescriptor(samplerDescriptor)
  checkNil(renderer.sampler, "Could not create a Metal sampler state")

proc recordQuad(
  window: Window,
  commandQueue: MTLCommandQueue,
  view: NSView,
  layer: CAMetalLayer,
  renderer: QuadRenderer,
  clear: MTLClearColor
) =
  ## Encodes a single textured-style quad draw.
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
    return

  let commandBuffer = commandQueue.commandBuffer()
  checkNil(commandBuffer, "Could not create a Metal command buffer")

  let renderPass = MTLRenderPassDescriptor.renderPassDescriptor()
  let colorAttachment =
    renderPass.colorAttachments().objectAtIndexedSubscript(0)
  colorAttachment.setTexture(drawable.texture())
  colorAttachment.setLoadAction(MTLLoadActionClear)
  colorAttachment.setStoreAction(MTLStoreActionStore)
  colorAttachment.setClearColor(clear)

  let encoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPass)
  checkNil(encoder, "Could not create a Metal render encoder")
  encoder.setRenderPipelineState(renderer.pipelineState)
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

  encoder.setFragmentTexture(renderer.texture, 0)
  encoder.setFragmentSamplerState(renderer.sampler, 0)
  encoder.drawPrimitives(MTLPrimitiveTypeTriangle, 0, 6)
  encoder.endEncoding()
  commandBuffer.presentDrawable(drawable)
  commandBuffer.commit()

proc main() =
  ## Opens a Windy window and draws a textured quad.
  let window = newWindow(
    "Metal Textured Quad",
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

  var renderer: QuadRenderer
  initRenderer(device, renderer)

  while not window.closeRequested:
    pollEvents()
    recordQuad(window, commandQueue, view, layer, renderer, Clear)

main()
