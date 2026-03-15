# Auto-generated from vendored Apple headers — do not edit manually.
# Regenerate with: nim r tools/generate_api.nim


import runtime, constants
export runtime, constants

type
  CAMetalDrawable* = distinct NSObject
  MTLDevice* = distinct NSObject
  MTLFunction* = distinct NSObject
  MTLLibrary* = distinct NSObject
  MTLCommandQueue* = distinct NSObject
  MTLCommandBuffer* = distinct NSObject
  MTLBuffer* = distinct NSObject
  MTLTexture* = distinct NSObject
  MTLSamplerState* = distinct NSObject
  MTLRenderPipelineState* = distinct NSObject
  MTLDepthStencilState* = distinct NSObject
  MTLCommandEncoder* = distinct NSObject
  MTLRenderCommandEncoder* = distinct NSObject
  MTLRenderPipelineColorAttachmentDescriptor* = distinct NSObject
  MTLRenderPipelineColorAttachmentDescriptorArray* = distinct NSObject
  MTLRenderPipelineDescriptor* = distinct NSObject
  MTLRenderPassAttachmentDescriptor* = distinct NSObject
  MTLRenderPassColorAttachmentDescriptor* = distinct MTLRenderPassAttachmentDescriptor
  MTLRenderPassColorAttachmentDescriptorArray* = distinct NSObject
  MTLRenderPassDepthAttachmentDescriptor* = distinct MTLRenderPassAttachmentDescriptor
  MTLRenderPassDescriptor* = distinct NSObject
  MTLTextureDescriptor* = distinct NSObject
  MTLSamplerDescriptor* = distinct NSObject
  MTLDepthStencilDescriptor* = distinct NSObject
  CAMetalLayer* = distinct CALayer
  MTLClearColor* {.bycopy.} = object
    red*: float64
    green*: float64
    blue*: float64
    alpha*: float64
  MTLOrigin* {.bycopy.} = object
    x*: uint
    y*: uint
    z*: uint
  MTLSize* {.bycopy.} = object
    width*: uint
    height*: uint
    depth*: uint
  MTLRegion* {.bycopy.} = object
    origin*: MTLOrigin
    size*: MTLSize
  MTLViewport* {.bycopy.} = object
    originX*: float64
    originY*: float64
    width*: float64
    height*: float64
    znear*: float64
    zfar*: float64
