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

echo "Testing parser snapshot content"
let irText = readFile(root / "headers" / "ir.json")
doAssert irText.contains("\"MTLCreateSystemDefaultDevice\"")
doAssert irText.contains("\"CAMetalLayer\"")

echo "metal4 smoke tests passed"
