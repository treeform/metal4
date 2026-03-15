# Auto-generated from vendored Apple headers — do not edit manually.
# Regenerate with: nim r tools/generate_api.nim


import types
export types

## Returns the preferred system Metal device.
proc MTLCreateSystemDefaultDevice*(): MTLDevice {.
  importc,
  cdecl,
  dynlib: "/System/Library/Frameworks/Metal.framework/Metal"
.}
