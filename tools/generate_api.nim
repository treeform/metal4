import
  std/[os, strformat, strutils]

import metal4_ir, metal4_parser

const
  Header =
    "# Auto-generated from vendored Apple headers — do not edit manually.\n" &
    "# Regenerate with: nim r tools/generate_api.nim\n"

  TargetEnums = [
    "MTLPixelFormat",
    "MTLPrimitiveType",
    "MTLLoadAction",
    "MTLStoreAction",
    "MTLSamplerMinMagFilter",
    "MTLSamplerMipFilter",
    "MTLSamplerAddressMode",
    "MTLTextureUsage",
    "MTLCompareFunction",
    "MTLWinding",
    "MTLCullMode"
  ]

  TargetStructs = [
    "MTLClearColor",
    "MTLOrigin",
    "MTLSize",
    "MTLRegion",
    "MTLViewport"
  ]

  TargetHandles = [
    "CAMetalDrawable",
    "MTLDevice",
    "MTLFunction",
    "MTLLibrary",
    "MTLCommandQueue",
    "MTLCommandBuffer",
    "MTLBuffer",
    "MTLTexture",
    "MTLSamplerState",
    "MTLRenderPipelineState",
    "MTLDepthStencilState",
    "MTLCommandEncoder",
    "MTLRenderCommandEncoder",
    "MTLRenderPipelineColorAttachmentDescriptor",
    "MTLRenderPipelineColorAttachmentDescriptorArray",
    "MTLRenderPipelineDescriptor",
    "MTLRenderPassAttachmentDescriptor",
    "MTLRenderPassColorAttachmentDescriptor",
    "MTLRenderPassColorAttachmentDescriptorArray",
    "MTLRenderPassDepthAttachmentDescriptor",
    "MTLRenderPassDescriptor",
    "MTLTextureDescriptor",
    "MTLSamplerDescriptor",
    "MTLDepthStencilDescriptor",
    "CAMetalLayer"
  ]

  TargetProperties = [
    ("CAMetalDrawable", "texture"),
    ("CAMetalDrawable", "layer"),
    ("CAMetalLayer", "device"),
    ("CAMetalLayer", "pixelFormat"),
    ("CAMetalLayer", "framebufferOnly"),
    ("CAMetalLayer", "drawableSize"),
    ("MTLTextureDescriptor", "usage"),
    ("MTLRenderPipelineDescriptor", "vertexFunction"),
    ("MTLRenderPipelineDescriptor", "fragmentFunction"),
    ("MTLRenderPipelineDescriptor", "colorAttachments"),
    ("MTLRenderPipelineDescriptor", "depthAttachmentPixelFormat"),
    ("MTLRenderPipelineColorAttachmentDescriptor", "pixelFormat"),
    ("MTLRenderPassAttachmentDescriptor", "texture"),
    ("MTLRenderPassAttachmentDescriptor", "loadAction"),
    ("MTLRenderPassAttachmentDescriptor", "storeAction"),
    ("MTLRenderPassColorAttachmentDescriptor", "clearColor"),
    ("MTLRenderPassDescriptor", "colorAttachments"),
    ("MTLRenderPassDescriptor", "depthAttachment"),
    ("MTLRenderPassDepthAttachmentDescriptor", "clearDepth"),
    ("MTLDepthStencilDescriptor", "depthCompareFunction"),
    ("MTLDepthStencilDescriptor", "depthWriteEnabled"),
    ("MTLSamplerDescriptor", "minFilter"),
    ("MTLSamplerDescriptor", "magFilter"),
    ("MTLSamplerDescriptor", "mipFilter"),
    ("MTLSamplerDescriptor", "sAddressMode"),
    ("MTLSamplerDescriptor", "tAddressMode")
  ]

  TargetMethods = [
    ("CAMetalLayer", "nextDrawable", "nextDrawable"),
    ("MTLDevice", "newCommandQueue", "newCommandQueue"),
    ("MTLDevice", "newBufferWithBytes", "newBufferWithBytes:length:options:"),
    ("MTLDevice", "newBufferWithLength", "newBufferWithLength:options:"),
    ("MTLDevice", "newTextureWithDescriptor", "newTextureWithDescriptor:"),
    ("MTLDevice", "newLibraryWithSource", "newLibraryWithSource:options:error:"),
    ("MTLDevice", "newRenderPipelineStateWithDescriptor", "newRenderPipelineStateWithDescriptor:error:"),
    ("MTLDevice", "newDepthStencilStateWithDescriptor", "newDepthStencilStateWithDescriptor:"),
    ("MTLDevice", "newSamplerStateWithDescriptor", "newSamplerStateWithDescriptor:"),
    ("MTLLibrary", "newFunctionWithName", "newFunctionWithName:"),
    ("MTLBuffer", "contents", "contents"),
    ("MTLCommandQueue", "commandBuffer", "commandBuffer"),
    ("MTLCommandBuffer", "renderCommandEncoderWithDescriptor", "renderCommandEncoderWithDescriptor:"),
    ("MTLCommandBuffer", "presentDrawable", "presentDrawable:"),
    ("MTLCommandBuffer", "commit", "commit"),
    ("MTLRenderPassColorAttachmentDescriptorArray", "objectAtIndexedSubscript", "objectAtIndexedSubscript:"),
    ("MTLRenderPipelineColorAttachmentDescriptorArray", "objectAtIndexedSubscript", "objectAtIndexedSubscript:"),
    ("MTLRenderPassDescriptor", "renderPassDescriptor", "renderPassDescriptor"),
    ("MTLTextureDescriptor", "texture2DDescriptorWithPixelFormat", "texture2DDescriptorWithPixelFormat:width:height:mipmapped:"),
    ("MTLTexture", "replaceRegion", "replaceRegion:mipmapLevel:withBytes:bytesPerRow:"),
    ("MTLCommandEncoder", "endEncoding", "endEncoding"),
    ("MTLRenderCommandEncoder", "setRenderPipelineState", "setRenderPipelineState:"),
    ("MTLRenderCommandEncoder", "setViewport", "setViewport:"),
    ("MTLRenderCommandEncoder", "setCullMode", "setCullMode:"),
    ("MTLRenderCommandEncoder", "setFrontFacingWinding", "setFrontFacingWinding:"),
    ("MTLRenderCommandEncoder", "setDepthStencilState", "setDepthStencilState:"),
    ("MTLRenderCommandEncoder", "setVertexBytes", "setVertexBytes:length:atIndex:"),
    ("MTLRenderCommandEncoder", "setVertexBuffer", "setVertexBuffer:offset:atIndex:"),
    ("MTLRenderCommandEncoder", "setFragmentTexture", "setFragmentTexture:atIndex:"),
    ("MTLRenderCommandEncoder", "setFragmentSamplerState", "setFragmentSamplerState:atIndex:"),
    ("MTLRenderCommandEncoder", "drawPrimitives", "drawPrimitives:vertexStart:vertexCount:")
  ]

  InitClasses = [
    "CAMetalLayer",
    "MTLRenderPipelineDescriptor",
    "MTLSamplerDescriptor",
    "MTLDepthStencilDescriptor"
  ]

  NimKeywords = [
    "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast",
    "concept", "const", "continue", "converter", "defer", "discard", "distinct",
    "div", "do", "elif", "else", "end", "enum", "except", "export", "finally",
    "for", "from", "func", "if", "import", "in", "include", "interface",
    "is", "isnot", "iterator", "let", "macro", "method", "mixin", "mod",
    "nil", "not", "notin", "object", "of", "or", "out", "proc", "ptr",
    "raise", "ref", "return", "shl", "shr", "static", "template", "try",
    "tuple", "type", "using", "var", "when", "while", "xor", "yield"
  ]

proc normalizeType(text: string): string =
  ## Normalizes a parsed C or Objective-C type string.
  result = text
  for token in [
    "nullable", "nonnull", "_Nullable", "_Nonnull",
    "__nullable", "__nonnull", "__strong", "__weak",
    "__autoreleasing", "__kindof", "__unsafe_unretained",
    "NS_RETURNS_INNER_POINTER"
  ]:
    result = result.replace(token, " ")
  result = result.replace("id <", "id<")
  result = result.replace("< ", "<")
  result = result.replace(" >", ">")
  result = result.replace("* ", "*")
  result = result.replace(" *", "*")
  result = result.multiReplace([
    ("\n", " "),
    ("\r", " "),
    ("\t", " ")
  ])
  while "  " in result:
    result = result.replace("  ", " ")
  result = result.strip()

proc nimType(text: string): string =
  ## Maps a parsed C or Objective-C type to a Nim type.
  let normalized = normalizeType(text)
  case normalized
  of "void":
    "void"
  of "BOOL":
    "bool"
  of "NSUInteger":
    "uint"
  of "NSInteger":
    "int"
  of "uint32_t":
    "uint32"
  of "uint64_t":
    "uint64"
  of "float":
    "float32"
  of "double":
    "float64"
  of "CGSize":
    "NSSize"
  of "CGRect":
    "NSRect"
  of "NSString":
    "NSString"
  of "NSError":
    "NSError"
  of "CGColorSpaceRef":
    "pointer"
  of "MTLCompileOptions":
    "ID"
  of "MTLResourceOptions":
    "uint"
  of "id":
    "ID"
  else:
    if normalized.startsWith("id<") and normalized.endsWith(">"):
      let handleName = normalized[3 .. ^2]
      if handleName == "MTLDrawable":
        return "CAMetalDrawable"
      return handleName
    if normalized.endsWith("**"):
      let base = normalized[0 ..< normalized.len - 2]
      return "ptr " & nimType(base & "*")
    if normalized.endsWith("*"):
      let base = normalized[0 ..< normalized.len - 1]
      if base == "void" or base == "const void":
        return "pointer"
      return nimType(base)
    if normalized.startsWith("const "):
      return nimType(normalized["const ".len .. ^1])
    normalized

proc safeName(name: string): string =
  ## Makes an identifier safe for Nim source generation.
  if name in NimKeywords:
    return name & "_mangle"
  name

proc pascalCase(name: string): string =
  ## Converts a lowerCamel identifier to PascalCase.
  if name.len == 0:
    return name
  name[0].toUpperAscii & name[1 .. ^1]

proc normalizeValue(value: string): string =
  ## Normalizes enum expressions for Nim output.
  result = value.strip()
  result = result.replace("NSUIntegerMax", "high(uint)")

proc requireEnum(ir: HeaderIr, name: string): EnumDef =
  ## Returns one enum definition or raises.
  for item in ir.enums:
    if item.name == name:
      return item
  raise newException(IOError, "Missing enum in IR: " & name)

proc requireStruct(ir: HeaderIr, name: string): StructDef =
  ## Returns one struct definition or raises.
  for item in ir.structs:
    if item.name == name:
      return item
  raise newException(IOError, "Missing struct in IR: " & name)

proc requireHandle(ir: HeaderIr, name: string): HandleDef =
  ## Returns one handle definition or raises.
  for item in ir.handles:
    if item.name == name:
      return item
  raise newException(IOError, "Missing handle in IR: " & name)

proc cleanBaseName(name: string): string =
  ## Extracts the base class name from an Objective-C inheritance clause.
  let normalized = normalizeType(name)
  if normalized.len == 0:
    return "NSObject"
  result = normalized.split({' ', '<', '{'})[0].strip()
  if result.len == 0:
    result = "NSObject"

proc requireProperty(ir: HeaderIr, owner, name: string): PropertyDef =
  ## Returns one property definition or raises.
  for item in ir.properties:
    if item.owner == owner and item.name == name:
      return item
  raise newException(
    IOError,
    "Missing property in IR: " & owner & "." & name
  )

proc requireMethod(ir: HeaderIr, owner, name, selector: string): MethodDef =
  ## Returns one method definition or raises.
  for item in ir.methods:
    if item.owner == owner and item.name == name and item.selector == selector:
      return item
  for item in ir.methods:
    if item.owner == owner and item.name.startsWith(name & " ") and
        item.selector.startsWith(selector):
      return item
  raise newException(
    IOError,
    "Missing method in IR: " & owner & "." & selector
  )

proc requireFunction(ir: HeaderIr, name: string): FunctionDef =
  ## Returns one function definition or raises.
  for item in ir.functions:
    if item.name == name:
      return item
  raise newException(IOError, "Missing function in IR: " & name)

proc generateConstants(ir: HeaderIr): string =
  ## Generates constants.nim.
  var lines = @[Header, "", "import runtime", "export runtime", "", "type"]
  for enumName in TargetEnums:
    let item = requireEnum(ir, enumName)
    lines.add(&"  {item.name}* = {nimType(item.baseType)}")
  lines.add("")
  lines.add("const")
  for enumName in TargetEnums:
    let item = requireEnum(ir, enumName)
    for value in item.values:
      lines.add(
        &"  {value.name}*: {item.name} = {normalizeValue(value.value)}"
      )
  result = lines.join("\n") & "\n"

proc generateTypes(ir: HeaderIr): string =
  ## Generates types.nim.
  var lines = @[Header, "", "import runtime, constants", "export runtime, constants", "", "type"]
  for handleName in TargetHandles:
    let item = requireHandle(ir, handleName)
    let baseName =
      if item.kind == "class" and item.baseName.len > 0:
        cleanBaseName(item.baseName)
      else:
        "NSObject"
    lines.add(&"  {item.name}* = distinct {baseName}")
  for structName in TargetStructs:
    let item = requireStruct(ir, structName)
    lines.add(&"  {item.name}* {{.bycopy.}} = object")
    for field in item.fields:
      lines.add(&"    {field.name}*: {nimType(field.typ)}")
  result = lines.join("\n") & "\n"

proc generateFunctions(ir: HeaderIr): string =
  ## Generates functions.nim.
  let item = requireFunction(ir, "MTLCreateSystemDefaultDevice")
  var lines = @[
    Header,
    "",
    "import types",
    "export types",
    "",
    "## Returns the preferred system Metal device."
  ]
  lines.add("proc MTLCreateSystemDefaultDevice*(): MTLDevice {.")
  lines.add("  importc,")
  lines.add("  cdecl,")
  lines.add("  dynlib: \"/System/Library/Frameworks/Metal.framework/Metal\"")
  lines.add(".}")
  discard item
  result = lines.join("\n") & "\n"

proc procSignature(
  name: string,
  selfType: string,
  params: seq[(string, string)],
  returnType: string
): string =
  ## Formats one generated proc signature.
  var pieces = @[&"  proc {name}*(self: {selfType}"]
  for item in params:
    pieces.add(&", {item[0]}: {item[1]}")
  var signature = pieces.join("")
  signature.add(")")
  if returnType != "void":
    signature.add(&": {returnType}")
  signature

proc classProcSignature(
  name: string,
  classType: string,
  params: seq[(string, string)],
  returnType: string
): string =
  ## Formats one generated class-proc signature.
  var pieces = @[&"  proc {name}*(class: typedesc[{classType}]"]
  for item in params:
    pieces.add(&", {item[0]}: {item[1]}")
  var signature = pieces.join("")
  signature.add(")")
  if returnType != "void":
    signature.add(&": {returnType}")
  signature

proc generateProtocols(ir: HeaderIr): string =
  ## Generates protocols.nim.
  var lines = @[
    Header,
    "",
    "import types",
    "export types",
    "",
    "converter toCALayer*(layer: CAMetalLayer): CALayer =",
    "  ## Converts CAMetalLayer to its CALayer base type.",
    "  cast[CALayer](layer)",
    "",
    "converter toMTLRenderPassAttachmentDescriptor*(",
    "  descriptor: MTLRenderPassColorAttachmentDescriptor",
    "): MTLRenderPassAttachmentDescriptor =",
    "  ## Converts the color attachment descriptor to its base type.",
    "  cast[MTLRenderPassAttachmentDescriptor](descriptor)",
    "",
    "converter toMTLRenderPassAttachmentDescriptor*(",
    "  descriptor: MTLRenderPassDepthAttachmentDescriptor",
    "): MTLRenderPassAttachmentDescriptor =",
    "  ## Converts the depth attachment descriptor to its base type.",
    "  cast[MTLRenderPassAttachmentDescriptor](descriptor)",
    "",
    "converter toMTLCommandEncoder*(",
    "  encoder: MTLRenderCommandEncoder",
    "): MTLCommandEncoder =",
    "  ## Converts the render encoder to its command-encoder base type.",
    "  cast[MTLCommandEncoder](encoder)",
    "",
    "objc:"
  ]

  for item in InitClasses:
    lines.add(&"  proc init*(self: {item}): {item}")

  for (owner, propName) in TargetProperties:
    let prop = requireProperty(ir, owner, propName)
    lines.add(
      procSignature(
        prop.getterName,
        owner,
        @[],
        nimType(prop.typ)
      )
    )
    if not prop.readonly:
      lines.add(
        procSignature(
          "set" & pascalCase(prop.name),
          owner,
          @[("x", nimType(prop.typ))],
          "void"
        )
      )

  for (owner, methodName, selector) in TargetMethods:
    let methodDef = requireMethod(ir, owner, methodName, selector)
    var params: seq[(string, string)]
    for i, param in methodDef.params:
      let paramName =
        if i == 0:
          "x"
        else:
          safeName(param.label)
      params.add((paramName, nimType(param.typ)))
    let procName = methodDef.name.split(' ')[0]
    if methodDef.isClassMethod:
      lines.add(
        classProcSignature(
          procName,
          owner,
          params,
          nimType(methodDef.returnType)
        )
      )
    else:
      lines.add(
        procSignature(
          procName,
          owner,
          params,
          nimType(methodDef.returnType)
        )
      )

  result = lines.join("\n") & "\n"

proc generateSwitchboard(): string =
  ## Generates the public src/metal4.nim switchboard.
  result =
    Header &
    "\n" &
    "when not defined(macosx):\n" &
    "  {.error: \"metal4 only runs on macOS.\".}\n" &
    "\n" &
    "import metal4/[constants, types, functions, protocols]\n" &
    "export constants, types, functions, protocols\n" &
    "\n" &
    "import metal4/[codes, runtime, extras, context]\n" &
    "export codes, runtime, extras, context\n"

proc main() =
  ## Generates the low-level Metal binding surface from vendored headers.
  let
    root = currentSourcePath.parentDir / ".."
    headersRoot = root / "headers"
    outDir = root / "src" / "metal4"
    ir = parseHeaders(headersRoot)

  createDir(outDir)
  writeFile(outDir / "constants.nim", generateConstants(ir))
  writeFile(outDir / "types.nim", generateTypes(ir))
  writeFile(outDir / "functions.nim", generateFunctions(ir))
  writeFile(outDir / "protocols.nim", generateProtocols(ir))
  writeFile(root / "src" / "metal4.nim", generateSwitchboard())

  echo "Generated low-level bindings:"
  echo "  constants.nim"
  echo "  types.nim"
  echo "  functions.nim"
  echo "  protocols.nim"
  echo "  metal4.nim"

when isMainModule:
  main()
