import metal4

type Pixel = array[4, uint8]

proc finish(command: MTLCommandBuffer) =
  ## Submits GPU work and requires successful native command completion.
  doAssert command.status() == MTLCommandBufferStatusNotEnqueued
  doAssert command.error().isNil
  command.commit()
  command.waitUntilCompleted()
  doAssert command.status() == MTLCommandBufferStatusCompleted,
    "Metal command failed: " & $command.error()
  doAssert command.error().isNil

proc near(actual, expected: Pixel) =
  ## Allows one UNORM rounding value when reading a native color clear.
  for i in 0 ..< actual.len:
    doAssert abs(actual[i].int - expected[i].int) <= 1,
      "Actual " & $actual & " expected " & $expected

proc testTransfers() =
  ## Verifies generated bindings on a real GPU without compiling a shader.
  let device = MTLCreateSystemDefaultDevice()
  doAssert not device.isNil, "This test requires a native Metal device"
  defer: cast[ID](device).release()
  doAssert ($device.name()).len > 0
  let queue = device.newCommandQueue()
  doAssert not queue.isNil
  defer: cast[ID](queue).release()

  echo "Testing odd-width texture upload and padded readback rows"
  let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatRGBA8Unorm,
    3,
    2,
    false
  )
  descriptor.setStorageMode(MTLStorageModeShared)
  descriptor.setUsage(MTLTextureUsageShaderRead or MTLTextureUsageRenderTarget)
  let texture = device.newTextureWithDescriptor(descriptor)
  doAssert not texture.isNil
  defer: cast[ID](texture).release()
  doAssert texture.width() == 3 and texture.height() == 2
  doAssert texture.mipmapLevelCount() == 1
  let
    pixels = [
      [255'u8, 0, 0, 255], [0'u8, 255, 0, 128], [0'u8, 0, 255, 64],
      [11'u8, 22, 33, 44], [55'u8, 66, 77, 88], [99'u8, 111, 123, 135]
    ]
    region = MTLRegion(size: MTLSize(width: 3, height: 2, depth: 1))
  texture.replaceRegion(region, 0, pixels[0].unsafeAddr, 12)
  var readback: array[32, uint8]
  for value in readback.mitems:
    value = 173
  texture.getBytes(readback[0].addr, 16, region, 0)
  for y in 0 ..< 2:
    for x in 0 ..< 3:
      for channel in 0 ..< 4:
        doAssert readback[y * 16 + x * 4 + channel] ==
          pixels[y * 3 + x][channel]
    for offset in 12 ..< 16:
      doAssert readback[y * 16 + offset] == 173

  echo "Testing GPU mip generation and command diagnostics"
  let mipDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
    MTLPixelFormatRGBA8Unorm,
    4,
    4,
    true
  )
  mipDescriptor.setStorageMode(MTLStorageModeShared)
  mipDescriptor.setUsage(
    MTLTextureUsageShaderRead or MTLTextureUsageRenderTarget
  )
  mipDescriptor.setMipmapLevelCount(3)
  let mipTexture = device.newTextureWithDescriptor(mipDescriptor)
  doAssert not mipTexture.isNil
  defer: cast[ID](mipTexture).release()
  doAssert mipTexture.width() == 4 and mipTexture.height() == 4
  doAssert mipTexture.mipmapLevelCount() == 3
  var uniformPixels: array[16, Pixel]
  for value in uniformPixels.mitems:
    value = [64'u8, 128, 192, 128]
  mipTexture.replaceRegion(
    MTLRegion(size: MTLSize(width: 4, height: 4, depth: 1)),
    0,
    uniformPixels[0].addr,
    16
  )
  let command = queue.commandBuffer()
  doAssert not command.isNil
  let blit = command.blitCommandEncoder()
  doAssert not blit.isNil
  blit.generateMipmapsForTexture(mipTexture)
  blit.endEncoding()
  command.finish()
  var mipPixel: Pixel
  mipTexture.getBytes(
    mipPixel[0].addr,
    4,
    MTLRegion(size: MTLSize(width: 1, height: 1, depth: 1)),
    2
  )
  doAssert mipPixel == [64'u8, 128, 192, 128]

  echo "Testing native render-target clear and GPU readback"
  let
    clearCommand = queue.commandBuffer()
    pass = MTLRenderPassDescriptor.renderPassDescriptor()
    attachment = pass.colorAttachments().objectAtIndexedSubscript(0)
  doAssert not clearCommand.isNil
  attachment.setTexture(mipTexture)
  attachment.setLoadAction(MTLLoadActionClear)
  attachment.setStoreAction(MTLStoreActionStore)
  attachment.setClearColor(MTLClearColor(
    red: 0.25,
    green: 0.5,
    blue: 0.75,
    alpha: 0.5
  ))
  let encoder = clearCommand.renderCommandEncoderWithDescriptor(pass)
  doAssert not encoder.isNil
  encoder.endEncoding()
  clearCommand.finish()
  var cleared: array[16, Pixel]
  mipTexture.getBytes(
    cleared[0].addr,
    16,
    MTLRegion(size: MTLSize(width: 4, height: 4, depth: 1)),
    0
  )
  for pixel in cleared:
    pixel.near([64'u8, 128, 191, 128])

autoreleasepool:
  testTransfers()

echo "Metal texture transfer tests passed"
