# Auto-generated from vendored Apple headers — do not edit manually.
# Regenerate with: nim r tools/generate_api.nim


import types
export types

converter toCALayer*(layer: CAMetalLayer): CALayer =
  ## Converts CAMetalLayer to its CALayer base type.
  cast[CALayer](layer)

converter toMTLRenderPassAttachmentDescriptor*(
  descriptor: MTLRenderPassColorAttachmentDescriptor
): MTLRenderPassAttachmentDescriptor =
  ## Converts the color attachment descriptor to its base type.
  cast[MTLRenderPassAttachmentDescriptor](descriptor)

converter toMTLRenderPassAttachmentDescriptor*(
  descriptor: MTLRenderPassDepthAttachmentDescriptor
): MTLRenderPassAttachmentDescriptor =
  ## Converts the depth attachment descriptor to its base type.
  cast[MTLRenderPassAttachmentDescriptor](descriptor)

converter toMTLCommandEncoder*(
  encoder: MTLRenderCommandEncoder
): MTLCommandEncoder =
  ## Converts the render encoder to its command-encoder base type.
  cast[MTLCommandEncoder](encoder)

objc:
  proc init*(self: CAMetalLayer): CAMetalLayer
  proc init*(self: MTLRenderPipelineDescriptor): MTLRenderPipelineDescriptor
  proc init*(self: MTLSamplerDescriptor): MTLSamplerDescriptor
  proc init*(self: MTLDepthStencilDescriptor): MTLDepthStencilDescriptor
  proc texture*(self: CAMetalDrawable): MTLTexture
  proc layer*(self: CAMetalDrawable): CAMetalLayer
  proc device*(self: CAMetalLayer): MTLDevice
  proc setDevice*(self: CAMetalLayer, x: MTLDevice)
  proc pixelFormat*(self: CAMetalLayer): MTLPixelFormat
  proc setPixelFormat*(self: CAMetalLayer, x: MTLPixelFormat)
  proc framebufferOnly*(self: CAMetalLayer): bool
  proc setFramebufferOnly*(self: CAMetalLayer, x: bool)
  proc drawableSize*(self: CAMetalLayer): NSSize
  proc setDrawableSize*(self: CAMetalLayer, x: NSSize)
  proc usage*(self: MTLTextureDescriptor): MTLTextureUsage
  proc setUsage*(self: MTLTextureDescriptor, x: MTLTextureUsage)
  proc vertexFunction*(self: MTLRenderPipelineDescriptor): MTLFunction
  proc setVertexFunction*(self: MTLRenderPipelineDescriptor, x: MTLFunction)
  proc fragmentFunction*(self: MTLRenderPipelineDescriptor): MTLFunction
  proc setFragmentFunction*(self: MTLRenderPipelineDescriptor, x: MTLFunction)
  proc colorAttachments*(self: MTLRenderPipelineDescriptor): MTLRenderPipelineColorAttachmentDescriptorArray
  proc depthAttachmentPixelFormat*(self: MTLRenderPipelineDescriptor): MTLPixelFormat
  proc setDepthAttachmentPixelFormat*(self: MTLRenderPipelineDescriptor, x: MTLPixelFormat)
  proc pixelFormat*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLPixelFormat
  proc setPixelFormat*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLPixelFormat)
  proc isBlendingEnabled*(self: MTLRenderPipelineColorAttachmentDescriptor): bool
  proc setBlendingEnabled*(self: MTLRenderPipelineColorAttachmentDescriptor, x: bool)
  proc sourceRGBBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLBlendFactor
  proc setSourceRGBBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLBlendFactor)
  proc destinationRGBBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLBlendFactor
  proc setDestinationRGBBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLBlendFactor)
  proc rgbBlendOperation*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLBlendOperation
  proc setRgbBlendOperation*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLBlendOperation)
  proc sourceAlphaBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLBlendFactor
  proc setSourceAlphaBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLBlendFactor)
  proc destinationAlphaBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLBlendFactor
  proc setDestinationAlphaBlendFactor*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLBlendFactor)
  proc alphaBlendOperation*(self: MTLRenderPipelineColorAttachmentDescriptor): MTLBlendOperation
  proc setAlphaBlendOperation*(self: MTLRenderPipelineColorAttachmentDescriptor, x: MTLBlendOperation)
  proc texture*(self: MTLRenderPassAttachmentDescriptor): MTLTexture
  proc setTexture*(self: MTLRenderPassAttachmentDescriptor, x: MTLTexture)
  proc loadAction*(self: MTLRenderPassAttachmentDescriptor): MTLLoadAction
  proc setLoadAction*(self: MTLRenderPassAttachmentDescriptor, x: MTLLoadAction)
  proc storeAction*(self: MTLRenderPassAttachmentDescriptor): MTLStoreAction
  proc setStoreAction*(self: MTLRenderPassAttachmentDescriptor, x: MTLStoreAction)
  proc clearColor*(self: MTLRenderPassColorAttachmentDescriptor): MTLClearColor
  proc setClearColor*(self: MTLRenderPassColorAttachmentDescriptor, x: MTLClearColor)
  proc colorAttachments*(self: MTLRenderPassDescriptor): MTLRenderPassColorAttachmentDescriptorArray
  proc depthAttachment*(self: MTLRenderPassDescriptor): MTLRenderPassDepthAttachmentDescriptor
  proc setDepthAttachment*(self: MTLRenderPassDescriptor, x: MTLRenderPassDepthAttachmentDescriptor)
  proc clearDepth*(self: MTLRenderPassDepthAttachmentDescriptor): float64
  proc setClearDepth*(self: MTLRenderPassDepthAttachmentDescriptor, x: float64)
  proc depthCompareFunction*(self: MTLDepthStencilDescriptor): MTLCompareFunction
  proc setDepthCompareFunction*(self: MTLDepthStencilDescriptor, x: MTLCompareFunction)
  proc depthWriteEnabled*(self: MTLDepthStencilDescriptor): bool
  proc setDepthWriteEnabled*(self: MTLDepthStencilDescriptor, x: bool)
  proc minFilter*(self: MTLSamplerDescriptor): MTLSamplerMinMagFilter
  proc setMinFilter*(self: MTLSamplerDescriptor, x: MTLSamplerMinMagFilter)
  proc magFilter*(self: MTLSamplerDescriptor): MTLSamplerMinMagFilter
  proc setMagFilter*(self: MTLSamplerDescriptor, x: MTLSamplerMinMagFilter)
  proc mipFilter*(self: MTLSamplerDescriptor): MTLSamplerMipFilter
  proc setMipFilter*(self: MTLSamplerDescriptor, x: MTLSamplerMipFilter)
  proc sAddressMode*(self: MTLSamplerDescriptor): MTLSamplerAddressMode
  proc setSAddressMode*(self: MTLSamplerDescriptor, x: MTLSamplerAddressMode)
  proc tAddressMode*(self: MTLSamplerDescriptor): MTLSamplerAddressMode
  proc setTAddressMode*(self: MTLSamplerDescriptor, x: MTLSamplerAddressMode)
  proc nextDrawable*(self: CAMetalLayer): CAMetalDrawable
  proc newCommandQueue*(self: MTLDevice): MTLCommandQueue
  proc newBufferWithBytes*(self: MTLDevice, x: pointer, length: uint, options: uint): MTLBuffer
  proc newBufferWithLength*(self: MTLDevice, x: uint, options: uint): MTLBuffer
  proc newTextureWithDescriptor*(self: MTLDevice, x: MTLTextureDescriptor): MTLTexture
  proc newLibraryWithSource*(self: MTLDevice, x: NSString, options: ID, error: ptr NSError): MTLLibrary
  proc newRenderPipelineStateWithDescriptor*(self: MTLDevice, x: MTLRenderPipelineDescriptor, error: ptr NSError): MTLRenderPipelineState
  proc newDepthStencilStateWithDescriptor*(self: MTLDevice, x: MTLDepthStencilDescriptor): MTLDepthStencilState
  proc newSamplerStateWithDescriptor*(self: MTLDevice, x: MTLSamplerDescriptor): MTLSamplerState
  proc newFunctionWithName*(self: MTLLibrary, x: NSString): MTLFunction
  proc contents*(self: MTLBuffer): pointer
  proc commandBuffer*(self: MTLCommandQueue): MTLCommandBuffer
  proc renderCommandEncoderWithDescriptor*(self: MTLCommandBuffer, x: MTLRenderPassDescriptor): MTLRenderCommandEncoder
  proc presentDrawable*(self: MTLCommandBuffer, x: CAMetalDrawable)
  proc commit*(self: MTLCommandBuffer)
  proc objectAtIndexedSubscript*(self: MTLRenderPassColorAttachmentDescriptorArray, x: uint): MTLRenderPassColorAttachmentDescriptor
  proc objectAtIndexedSubscript*(self: MTLRenderPipelineColorAttachmentDescriptorArray, x: uint): MTLRenderPipelineColorAttachmentDescriptor
  proc renderPassDescriptor*(class: typedesc[MTLRenderPassDescriptor]): MTLRenderPassDescriptor
  proc texture2DDescriptorWithPixelFormat*(class: typedesc[MTLTextureDescriptor], x: MTLPixelFormat, width: uint, height: uint, mipmapped: bool): MTLTextureDescriptor
  proc replaceRegion*(self: MTLTexture, x: MTLRegion, mipmapLevel: uint, withBytes: pointer, bytesPerRow: uint)
  proc endEncoding*(self: MTLCommandEncoder)
  proc setRenderPipelineState*(self: MTLRenderCommandEncoder, x: MTLRenderPipelineState)
  proc setViewport*(self: MTLRenderCommandEncoder, x: MTLViewport)
  proc setCullMode*(self: MTLRenderCommandEncoder, x: MTLCullMode)
  proc setFrontFacingWinding*(self: MTLRenderCommandEncoder, x: MTLWinding)
  proc setDepthStencilState*(self: MTLRenderCommandEncoder, x: MTLDepthStencilState)
  proc setVertexBytes*(self: MTLRenderCommandEncoder, x: pointer, length: uint, atIndex: uint)
  proc setVertexBuffer*(self: MTLRenderCommandEncoder, x: MTLBuffer, offset: uint, atIndex: uint)
  proc setFragmentTexture*(self: MTLRenderCommandEncoder, x: MTLTexture, atIndex: uint)
  proc setFragmentSamplerState*(self: MTLRenderCommandEncoder, x: MTLSamplerState, atIndex: uint)
  proc drawPrimitives*(self: MTLRenderCommandEncoder, x: MTLPrimitiveType, vertexStart: uint, vertexCount: uint)
