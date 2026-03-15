import
  std/os,
  pixie,
  vmath,
  windy,
  windy/platforms/macos/[macdefs, objc],
  metal4

const
  InitialWidth = 1280
  InitialHeight = 800
  SheetCells = 8
  SpriteDrawSize = 24.0'f32
  SpriteDensity = 850.0'f32
  MinSpriteCount = 96
  Clear = MTLClearColor(
    red: 0.08,
    green: 0.08,
    blue: 0.1,
    alpha: 1.0
  )

type
  SpriteSheetError = object of CatchableError

  SpriteVertex = object
    position: array[2, float32]
    uv: array[2, float32]

  SpriteRenderer = object
    pipelineState: MTLRenderPipelineState
    texture: MTLTexture
    sampler: MTLSamplerState
    vertexBuffer: MTLBuffer
    vertexBufferPtr: pointer
    maxVertexCount: int

  SpriteDrawer = object
    vertices: seq[SpriteVertex]
    viewportSize: IVec2

proc texturePath(): string =
  ## Returns the sprite sheet path beside this example.
  currentSourcePath.parentDir / "testSpriteSheet.png"

proc clampWindowSize(size: IVec2): IVec2 =
  ## Clamps the window size to valid drawable dimensions.
  ivec2(max(1'i32, size.x), max(1'i32, size.y))

proc spriteCountForSize(size: IVec2): int =
  ## Returns a sprite count scaled by the window area.
  let area = size.x.float32 * size.y.float32
  max(MinSpriteCount, int(area / SpriteDensity))

proc maxVertexCountForSize(size: IVec2): int =
  ## Returns the vertex capacity needed for the current window.
  spriteCountForSize(size) * 6

proc hash32(value: uint32): uint32 =
  ## Returns a small deterministic hash for pseudo-random placement.
  result = value
  result = result xor (result shr 16)
  result *= 0x7feb352d'u32
  result = result xor (result shr 15)
  result *= 0x846ca68b'u32
  result = result xor (result shr 16)

proc random01(seed: uint32): float32 =
  ## Returns a deterministic float in the 0 to 1 range.
  (hash32(seed) and 0x00ff_ffff'u32).float32 / 16_777_215.0'f32

proc randomInt(seed: uint32, limit: int): int =
  ## Returns a deterministic integer in the 0 to limit range.
  if limit <= 0:
    return 0
  int(hash32(seed) mod uint32(limit + 1))

proc uvArray(v: Vec2): array[2, float32] =
  ## Converts a UV vector to a plain array.
  [v.x, v.y]

proc clipArray(p: Vec2): array[2, float32] =
  ## Converts a clip-space vector to a plain array.
  [p.x, p.y]

proc screenToClip(drawer: SpriteDrawer, pos: Vec2): Vec2 =
  ## Converts a pixel-space position into clip space.
  let
    width = max(1.0'f32, drawer.viewportSize.x.float32)
    height = max(1.0'f32, drawer.viewportSize.y.float32)
  vec2(
    (pos.x / width) * 2.0'f32 - 1.0'f32,
    1.0'f32 - (pos.y / height) * 2.0'f32
  )

proc beginDraw(drawer: var SpriteDrawer, viewportSize: IVec2) =
  ## Starts a new sprite batch for the current viewport.
  drawer.viewportSize = clampWindowSize(viewportSize)
  drawer.vertices.setLen(0)

proc pushVertex(drawer: var SpriteDrawer, position, uv: Vec2) =
  ## Appends one sprite vertex to the current batch.
  drawer.vertices.add(
    SpriteVertex(
      position: clipArray(position),
      uv: uvArray(uv)
    )
  )

proc drawQuad(
  drawer: var SpriteDrawer,
  positions: array[4, Vec2],
  uvs: array[4, Vec2]
) =
  ## Draws one textured quad into the current batch.
  let clipPositions = [
    drawer.screenToClip(positions[0]),
    drawer.screenToClip(positions[1]),
    drawer.screenToClip(positions[2]),
    drawer.screenToClip(positions[3])
  ]
  drawer.pushVertex(clipPositions[0], uvs[0])
  drawer.pushVertex(clipPositions[1], uvs[1])
  drawer.pushVertex(clipPositions[2], uvs[2])
  drawer.pushVertex(clipPositions[0], uvs[0])
  drawer.pushVertex(clipPositions[2], uvs[2])
  drawer.pushVertex(clipPositions[3], uvs[3])

proc drawIcon(drawer: var SpriteDrawer, icon: IVec2, pos: Vec2) =
  ## Draws one icon from the 8x8 sprite sheet at a pixel position.
  let
    iconSize = vec2(SpriteDrawSize, SpriteDrawSize)
    cellSize = 1.0'f32 / SheetCells.float32
    uvMin = vec2(
      icon.x.float32 * cellSize,
      icon.y.float32 * cellSize
    )
    uvMax = uvMin + vec2(cellSize, cellSize)
    positions = [
      pos,
      pos + vec2(iconSize.x, 0.0'f32),
      pos + iconSize,
      pos + vec2(0.0'f32, iconSize.y)
    ]
    uvs = [
      uvMin,
      vec2(uvMax.x, uvMin.y),
      uvMax,
      vec2(uvMin.x, uvMax.y)
    ]
  drawer.drawQuad(positions, uvs)

proc createVertexBuffer(
  device: MTLDevice,
  renderer: var SpriteRenderer,
  maxVertexCount: int
) =
  ## Creates a persistently mapped dynamic vertex buffer.
  renderer.vertexBuffer = device.newBufferWithLength(
    (maxVertexCount * sizeof(SpriteVertex)).uint,
    0
  )
  checkNil(renderer.vertexBuffer, "Could not create a vertex buffer")
  renderer.vertexBufferPtr = renderer.vertexBuffer.contents()
  checkNil(renderer.vertexBufferPtr, "Could not map the vertex buffer")
  renderer.maxVertexCount = maxVertexCount

proc buildMipChain(image: Image): seq[Image] =
  ## Builds a full mip chain from the base level down to 1x1.
  result.add(image)
  var current = image
  while current.width > 1 or current.height > 1:
    current = current.minifyBy2()
    result.add(current)

proc loadTexture(device: MTLDevice): MTLTexture =
  ## Loads the sprite sheet image and uploads it to a texture.
  let image = readImage(texturePath())
  let mipImages = buildMipChain(image)
  let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatRGBA8Unorm,
    mipImages[0].width.uint,
    mipImages[0].height.uint,
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

proc initRenderer(
  device: MTLDevice,
  renderer: var SpriteRenderer,
  maxVertexCount: int
) =
  ## Creates the sprite pipeline, texture, and dynamic vertex buffer.
  const ShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct SpriteVertex {
  packed_float2 position;
  packed_float2 uv;
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
};

vertex VertexOut vertexMain(
  uint vertexId [[vertex_id]],
  constant SpriteVertex *vertices [[buffer(0)]]
) {
  VertexOut out;
  out.position = float4(float2(vertices[vertexId].position), 0.0, 1.0);
  out.uv = float2(vertices[vertexId].uv);
  return out;
}

fragment float4 fragmentMain(
  VertexOut in [[stage_in]],
  texture2d<float> tex [[texture(0)]],
  sampler texSampler [[sampler(0)]]
) {
  float4 color = tex.sample(texSampler, in.uv);
  if (color.a <= 0.01) {
    discard_fragment();
  }
  return color;
}
"""

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
  samplerDescriptor.setMipFilter(MTLSamplerMipFilterLinear)
  samplerDescriptor.setSAddressMode(MTLSamplerAddressModeClampToEdge)
  samplerDescriptor.setTAddressMode(MTLSamplerAddressModeClampToEdge)
  renderer.sampler = device.newSamplerStateWithDescriptor(samplerDescriptor)
  checkNil(renderer.sampler, "Could not create a Metal sampler state")

  createVertexBuffer(device, renderer, maxVertexCount)

proc recordSprites(
  window: Window,
  commandQueue: MTLCommandQueue,
  view: NSView,
  layer: CAMetalLayer,
  renderer: SpriteRenderer,
  vertexCount: int,
  clear: MTLClearColor
) =
  ## Records the draw pass for the current sprite batch.
  autoreleasepool:
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
    encoder.setCullMode(MTLCullModeNone)
    encoder.setVertexBuffer(renderer.vertexBuffer, 0, 0)
    encoder.setFragmentTexture(renderer.texture, 0)
    encoder.setFragmentSamplerState(renderer.sampler, 0)
    if vertexCount > 0:
      encoder.drawPrimitives(MTLPrimitiveTypeTriangle, 0, vertexCount.uint)
    encoder.endEncoding()
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()

proc endDraw(
  drawer: SpriteDrawer,
  window: Window,
  commandQueue: MTLCommandQueue,
  view: NSView,
  layer: CAMetalLayer,
  renderer: SpriteRenderer,
  clear: MTLClearColor
) =
  ## Uploads the current batch and records the sprite draw.
  if drawer.vertices.len > renderer.maxVertexCount:
    raise newException(
      SpriteSheetError,
      "Sprite batch exceeded dynamic vertex buffer capacity"
    )

  if drawer.vertices.len > 0:
    copyMem(
      renderer.vertexBufferPtr,
      unsafeAddr drawer.vertices[0],
      drawer.vertices.len * sizeof(SpriteVertex)
    )

  recordSprites(
    window,
    commandQueue,
    view,
    layer,
    renderer,
    drawer.vertices.len,
    clear
  )

proc ensureVertexCapacity(
  device: MTLDevice,
  renderer: var SpriteRenderer,
  windowSize: IVec2
) =
  ## Grows the dynamic sprite buffer when the viewport area increases.
  let size = clampWindowSize(windowSize)
  let requiredVertexCount = maxVertexCountForSize(size)
  if requiredVertexCount > renderer.maxVertexCount:
    createVertexBuffer(device, renderer, requiredVertexCount)

proc main() =
  ## Opens a Windy window and draws a sprite sheet batch.
  let window = newWindow(
    "Metal Sprite Sheet",
    ivec2(InitialWidth.int32, InitialHeight.int32)
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
    renderer: SpriteRenderer
    drawer: SpriteDrawer
    renderSize = clampWindowSize(window.size)
    pendingResize = false

  window.onResize = proc() =
    pendingResize = true

  initRenderer(device, renderer, maxVertexCountForSize(renderSize))

  while not window.closeRequested:
    pollEvents()

    let currentSize = clampWindowSize(window.size)
    if pendingResize or currentSize != renderSize:
      renderSize = currentSize
      pendingResize = false
      ensureVertexCapacity(device, renderer, renderSize)

    drawer.beginDraw(renderSize)
    let
      spriteCount = spriteCountForSize(renderSize)
      maxX = max(0.0'f32, renderSize.x.float32 - SpriteDrawSize)
      maxY = max(0.0'f32, renderSize.y.float32 - SpriteDrawSize)
      baseSeed =
        uint32(renderSize.x) xor
        (uint32(renderSize.y) shl 16) xor
        0x1357_9bdf'u32

    for i in 0 ..< spriteCount:
      let
        seed = baseSeed + uint32(i) * 0x9e37_79b9'u32
        pos = vec2(
          random01(seed xor 0x68bc_21eb'u32) * maxX,
          random01(seed xor 0x02e5_be93'u32) * maxY
        )
        icon = ivec2(
          randomInt(seed xor 0xa5a5_1021'u32, SheetCells - 1).int32,
          randomInt(seed xor 0x1f12_4bb5'u32, SheetCells - 1).int32
        )
      drawer.drawIcon(icon, pos)

    drawer.endDraw(window, commandQueue, view, layer, renderer, Clear)

main()
