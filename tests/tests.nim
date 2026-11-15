import
  std/[os, strutils],
  metal4

echo "Testing vendored headers"
let root = currentSourcePath.parentDir / ".."
doAssert fileExists(root / "headers" / "manifest.json")
doAssert fileExists(root / "headers" / "ir.json")

echo "Testing generated bindings"
let clear = MTLClearColor(
  red: 0.0,
  green: 0.0,
  blue: 0.0,
  alpha: 1.0
)
doAssert clear.alpha == 1.0
doAssert MTLPixelFormatBGRA8Unorm == 80
doAssert MTLPrimitiveTypeTriangle == 3
doAssert MTLCompareFunctionLess == 1
doAssert MTLBlendFactorOne == 1
doAssert MTLBlendOperationAdd == 0

echo "Testing context and helper surface"
doAssert compiles(0.MTLDevice)
doAssert compiles(CAMetalLayer.alloc().init())
doAssert compiles(
  MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatRGBA8Unorm,
    16,
    16,
    false
  )
)
doAssert compiles(MetalContext())
doAssert compiles(
  MTLRenderPipelineColorAttachmentDescriptor(
    0
  ).setBlendingEnabled(true)
)
doAssert compiles(
  MTLRenderPipelineColorAttachmentDescriptor(
    0
  ).setSourceRGBBlendFactor(MTLBlendFactorOne)
)

echo "Testing renderer binding surface"
doAssert compiles(block:
  let
    device = cast[MTLDevice](0)
    command = cast[MTLCommandBuffer](0)
    encoder = cast[MTLRenderCommandEncoder](0)
    texture = cast[MTLTexture](0)
    deviceName: NSString = device.name()
    status: MTLCommandBufferStatus = command.status()
    error: NSError = command.error()
    width: uint = texture.width()
    height: uint = texture.height()
    levels: uint = texture.mipmapLevelCount()
  command.waitUntilCompleted()
  encoder.setFragmentBytes(nil, 0, 1)
  texture.getBytes(nil, 4, MTLRegion(), 0)
  let blit = command.blitCommandEncoder()
  blit.generateMipmapsForTexture(texture)
  let base: MTLCommandEncoder = blit
  base.endEncoding()
  blit.endEncoding()
)

echo "Testing native vertex and texture descriptors"
autoreleasepool:
  let
    vertex = MTLVertexDescriptor.vertexDescriptor()
    attribute = vertex.attributes().objectAtIndexedSubscript(0)
    layout = vertex.layouts().objectAtIndexedSubscript(2)
    texture = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
      MTLPixelFormatRGBA8Unorm,
      4,
      4,
      true
    )
  doAssert not vertex.isNil
  attribute.setFormat(MTLVertexFormatFloat2)
  attribute.setOffset(4)
  attribute.setBufferIndex(2)
  layout.setStride(12)
  layout.setStepFunction(MTLVertexStepFunctionPerVertex)
  doAssert attribute.format() == MTLVertexFormatFloat2
  doAssert attribute.offset() == 4
  doAssert attribute.bufferIndex() == 2
  doAssert layout.stride() == 12
  doAssert layout.stepFunction() == MTLVertexStepFunctionPerVertex
  texture.setStorageMode(MTLStorageModeShared)
  texture.setMipmapLevelCount(3)
  doAssert texture.storageMode() == MTLStorageModeShared
  doAssert texture.mipmapLevelCount() == 3
  let pipeline = MTLRenderPipelineDescriptor.alloc().init()
  defer: cast[ID](pipeline).release()
  pipeline.setVertexDescriptor(vertex)
  doAssert not pipeline.vertexDescriptor().isNil

echo "Testing parser snapshot content"
let irText = readFile(root / "headers" / "ir.json")
doAssert irText.contains("\"MTLCreateSystemDefaultDevice\"")
doAssert irText.contains("\"CAMetalLayer\"")
doAssert irText.contains("\"MTLVertexDescriptor\"")
doAssert irText.contains("\"MTLBlitCommandEncoder\"")

echo "metal4 smoke tests passed"
