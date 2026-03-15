import
  std/os,
  pixie,
  vmath,
  windy,
  windy/platforms/macos/[macdefs, objc],
  metal4

type
  CubeVertex = object
    position: array[3, float32]
    uv: array[2, float32]

  Uniforms = object
    mvp: array[16, float32]

  CubeRenderer = object
    pipelineState: MTLRenderPipelineState
    depthState: MTLDepthStencilState
    texture: MTLTexture
    depthTexture: MTLTexture
    depthWidth: int
    depthHeight: int
    sampler: MTLSamplerState
    uniforms: Uniforms

const
  Width = 1280
  Height = 800
  Clear = MTLClearColor(
    red: 0.05,
    green: 0.05,
    blue: 0.1,
    alpha: 1.0
  )
  CubeVertices = [
    CubeVertex(position: [-1.0'f32, 1.0'f32, 1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, 1.0'f32], uv: [1.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, 1.0'f32], uv: [1.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, 1.0'f32, 1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, 1.0'f32], uv: [0.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, 1.0'f32], uv: [1.0'f32, 1.0'f32]),

    CubeVertex(position: [1.0'f32, 1.0'f32, -1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, -1.0'f32], uv: [1.0'f32, 1.0'f32]),
    CubeVertex(position: [-1.0'f32, 1.0'f32, -1.0'f32], uv: [1.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, -1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, -1.0'f32], uv: [0.0'f32, 1.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, -1.0'f32], uv: [1.0'f32, 1.0'f32]),

    CubeVertex(position: [-1.0'f32, 1.0'f32, -1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, 1.0'f32], uv: [1.0'f32, 1.0'f32]),
    CubeVertex(position: [-1.0'f32, 1.0'f32, 1.0'f32], uv: [1.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, 1.0'f32, -1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, -1.0'f32], uv: [0.0'f32, 1.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, 1.0'f32], uv: [1.0'f32, 1.0'f32]),

    CubeVertex(position: [1.0'f32, 1.0'f32, 1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, -1.0'f32], uv: [1.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, -1.0'f32], uv: [1.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, 1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, 1.0'f32], uv: [0.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, -1.0'f32], uv: [1.0'f32, 1.0'f32]),

    CubeVertex(position: [-1.0'f32, 1.0'f32, -1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, 1.0'f32], uv: [1.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, -1.0'f32], uv: [1.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, 1.0'f32, -1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, 1.0'f32, 1.0'f32], uv: [0.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, 1.0'f32, 1.0'f32], uv: [1.0'f32, 1.0'f32]),

    CubeVertex(position: [-1.0'f32, -1.0'f32, 1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, -1.0'f32], uv: [1.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, 1.0'f32], uv: [1.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, 1.0'f32], uv: [0.0'f32, 0.0'f32]),
    CubeVertex(position: [-1.0'f32, -1.0'f32, -1.0'f32], uv: [0.0'f32, 1.0'f32]),
    CubeVertex(position: [1.0'f32, -1.0'f32, -1.0'f32], uv: [1.0'f32, 1.0'f32])
  ]
  ShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct CubeVertex {
  packed_float3 position;
  packed_float2 uv;
};

struct Uniforms {
  float4x4 mvp;
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
};

vertex VertexOut vertexMain(
  uint vertexId [[vertex_id]],
  constant CubeVertex *vertices [[buffer(0)]],
  constant Uniforms &uniforms [[buffer(1)]]
) {
  VertexOut out;
  float4 position = float4(float3(vertices[vertexId].position), 1.0);
  out.position = uniforms.mvp * position;
  out.uv = float2(vertices[vertexId].uv);
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

proc perspectiveMetal(
  fovY,
  aspect,
  nearPlane,
  farPlane: float32
): Mat4 =
  ## Returns a z-forward perspective for Metal's 0..1 depth range.
  let
    h = 1.0'f32 / tan(fovY * 0.5'f32)
    w = h / aspect
    depth = farPlane - nearPlane
  result[0, 0] = w
  result[0, 1] = 0
  result[0, 2] = 0
  result[0, 3] = 0
  result[1, 0] = 0
  result[1, 1] = h
  result[1, 2] = 0
  result[1, 3] = 0
  result[2, 0] = 0
  result[2, 1] = 0
  result[2, 2] = farPlane / depth
  result[2, 3] = 1
  result[3, 0] = 0
  result[3, 1] = 0
  result[3, 2] = -(nearPlane * farPlane) / depth
  result[3, 3] = 0

proc mat4ToArray(matrix: Mat4): array[16, float32] =
  ## Flattens a matrix in vmath's column-major order.
  var index = 0
  for i in 0 ..< 4:
    for j in 0 ..< 4:
      result[index] = matrix[i, j]
      inc index

proc updateTransform(
  renderer: var CubeRenderer,
  aspect: float32,
  frame: uint64
) =
  ## Updates the cube MVP matrix.
  let
    time = frame.float32 / 60.0'f32
    model =
      translate(vec3(0.0'f32, 0.0'f32, 5.0'f32)) *
      rotateY(time * 0.7'f32) *
      rotateX(time * 0.35'f32)
    view = mat4()
    proj = perspectiveMetal(60.0'f32.toRadians, aspect, 0.1'f32, 100.0'f32)
    mvp = proj * view * model
  renderer.uniforms.mvp = mat4ToArray(mvp)

proc loadTexture(device: MTLDevice): MTLTexture =
  ## Loads the example texture and its mip chain.
  let image = readImage(texturePath())
  var mipImages = @[image]
  var current = image
  while current.width > 1 or current.height > 1:
    current = current.minifyBy2()
    mipImages.add(current)

  let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatRGBA8Unorm,
    image.width.uint,
    image.height.uint,
    true
  )
  descriptor.setUsage(MTLTextureUsageShaderRead)
  result = device.newTextureWithDescriptor(descriptor)
  checkNil(result, "Could not create a Metal texture")

  for i, mipImage in mipImages:
    result.replaceRegion(
      MTLRegion(
        origin: MTLOrigin(x: 0, y: 0, z: 0),
        size: MTLSize(
          width: mipImage.width.uint,
          height: mipImage.height.uint,
          depth: 1
        )
      ),
      i.uint,
      unsafeAddr mipImage.data[0],
      (mipImage.width * 4).uint
    )

proc createDepthTexture(device: MTLDevice, width, height: int): MTLTexture =
  ## Creates a depth texture matching the drawable size.
  let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatDepth32Float,
    width.uint,
    height.uint,
    false
  )
  descriptor.setUsage(MTLTextureUsageRenderTarget)
  result = device.newTextureWithDescriptor(descriptor)
  checkNil(result, "Could not create a depth texture")

proc initRenderer(
  device: MTLDevice,
  width,
  height: int,
  renderer: var CubeRenderer
) =
  ## Compiles the shaders and creates the cube resources.
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
  pipelineDescriptor.setDepthAttachmentPixelFormat(MTLPixelFormatDepth32Float)

  error = 0.NSError
  renderer.pipelineState = device.newRenderPipelineStateWithDescriptor(
    pipelineDescriptor,
    error.addr
  )
  checkNSError(error, "Could not create Metal pipeline")
  checkNil(renderer.pipelineState, "Metal pipeline state was nil")

  let depthDescriptor = MTLDepthStencilDescriptor.alloc().init()
  checkNil(depthDescriptor, "Could not create a depth descriptor")
  depthDescriptor.setDepthCompareFunction(MTLCompareFunctionLess)
  depthDescriptor.setDepthWriteEnabled(true)
  renderer.depthState = device.newDepthStencilStateWithDescriptor(
    depthDescriptor
  )
  checkNil(renderer.depthState, "Could not create a depth state")

  renderer.texture = loadTexture(device)
  renderer.depthTexture = createDepthTexture(device, width, height)
  renderer.depthWidth = width
  renderer.depthHeight = height

  let samplerDescriptor = MTLSamplerDescriptor.alloc().init()
  checkNil(samplerDescriptor, "Could not create a Metal sampler descriptor")
  samplerDescriptor.setMinFilter(MTLSamplerMinMagFilterLinear)
  samplerDescriptor.setMagFilter(MTLSamplerMinMagFilterLinear)
  samplerDescriptor.setMipFilter(MTLSamplerMipFilterLinear)
  samplerDescriptor.setSAddressMode(MTLSamplerAddressModeRepeat)
  samplerDescriptor.setTAddressMode(MTLSamplerAddressModeRepeat)
  renderer.sampler = device.newSamplerStateWithDescriptor(samplerDescriptor)
  checkNil(renderer.sampler, "Could not create a Metal sampler state")

proc recordCube(
  window: Window,
  commandQueue: MTLCommandQueue,
  device: MTLDevice,
  view: NSView,
  layer: CAMetalLayer,
  renderer: var CubeRenderer
) =
  ## Encodes a textured cube draw.
  let
    bounds = view.bounds
    backing = view.convertRectToBacking(bounds)

  layer.setFrame(bounds)
  layer.setContentsScale(window.contentScale.float64)
  layer.setDrawableSize(
    NSMakeSize(backing.size.width, backing.size.height)
  )

  let backingWidth = max(1, backing.size.width.int)
  let backingHeight = max(1, backing.size.height.int)
  if renderer.depthWidth != backingWidth or
      renderer.depthHeight != backingHeight:
    renderer.depthTexture = createDepthTexture(
      device,
      backingWidth,
      backingHeight
    )
    renderer.depthWidth = backingWidth
    renderer.depthHeight = backingHeight

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
  colorAttachment.setClearColor(Clear)

  let depthAttachment = renderPass.depthAttachment()
  depthAttachment.setTexture(renderer.depthTexture)
  depthAttachment.setLoadAction(MTLLoadActionClear)
  depthAttachment.setStoreAction(MTLStoreActionDontCare)
  depthAttachment.setClearDepth(1.0)

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
  encoder.setFrontFacingWinding(MTLWindingClockwise)
  encoder.setCullMode(MTLCullModeBack)
  encoder.setDepthStencilState(renderer.depthState)
  encoder.setVertexBytes(
    unsafeAddr CubeVertices[0],
    sizeof(CubeVertices).uint,
    0
  )
  encoder.setVertexBytes(
    unsafeAddr renderer.uniforms,
    sizeof(renderer.uniforms).uint,
    1
  )
  encoder.setFragmentTexture(renderer.texture, 0)
  encoder.setFragmentSamplerState(renderer.sampler, 0)
  encoder.drawPrimitives(MTLPrimitiveTypeTriangle, 0, CubeVertices.len.uint)
  encoder.endEncoding()
  commandBuffer.presentDrawable(drawable)
  commandBuffer.commit()

proc main() =
  ## Opens a Windy window and draws a textured cube.
  let window = newWindow(
    "Metal Basic Cube",
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
  view.setLayer(layer)

  var renderer: CubeRenderer
  initRenderer(device, Width, Height, renderer)

  var frame = 0'u64

  while not window.closeRequested:
    pollEvents()
    let
      bounds = view.bounds
      backing = view.convertRectToBacking(bounds)
      aspect = max(1.0, backing.size.width) / max(1.0, backing.size.height)
    updateTransform(renderer, aspect, frame)
    recordCube(window, commandQueue, device, view, layer, renderer)
    inc frame

main()
