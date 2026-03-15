import
  std/[math, os, strutils],
  vmath,
  windy,
  windy/platforms/macos/[macdefs, objc],
  metal4

const
  Width = 1280
  Height = 800
  RotateScale = 0.01'f32
  ZoomScale = 0.01'f32
  DragZoomScale = 0.01'f32
  MinDistance = 1.0'f32
  MaxDistance = 8.0'f32
  MinPitch = -1.45'f32
  MaxPitch = 1.45'f32
  Clear = MTLClearColor(
    red: 0.05,
    green: 0.05,
    blue: 0.08,
    alpha: 1.0
  )

type
  ViewerObjError = object of CatchableError

  ObjVertex = object
    position: array[3, float32]
    normal: array[3, float32]

  ObjMesh = object
    vertices: seq[ObjVertex]

  CameraState = object
    yaw: float32
    pitch: float32
    distance: float32

  Uniforms = object
    mvp: array[16, float32]
    model: array[16, float32]

  ObjRenderer = object
    pipelineState: MTLRenderPipelineState
    depthState: MTLDepthStencilState
    vertexBuffer: MTLBuffer
    vertexCount: uint
    depthTexture: MTLTexture
    depthWidth: int
    depthHeight: int
    uniforms: Uniforms

proc objPath(): string =
  ## Returns the Stanford bunny path beside this example.
  currentSourcePath.parentDir / "bunny.obj"

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

proc toFloatArray(v: Vec3): array[3, float32] =
  ## Converts a vector into a plain float array.
  [v.x, v.y, v.z]

proc parseFloat32(value: string): float32 =
  ## Parses a float32 from text.
  try:
    parseFloat(value).float32
  except ValueError:
    raise newException(ViewerObjError, "Invalid float in OBJ: " & value)

proc parseObjIndex(value: string, vertexCount: int): int =
  ## Parses a 1-based OBJ vertex index into a 0-based index.
  if value.len == 0:
    raise newException(ViewerObjError, "OBJ face is missing a vertex index")

  let rawIndex =
    try:
      parseInt(value)
    except ValueError:
      raise newException(ViewerObjError, "Invalid OBJ face index: " & value)

  result =
    if rawIndex > 0:
      rawIndex - 1
    elif rawIndex < 0:
      vertexCount + rawIndex
    else:
      raise newException(ViewerObjError, "OBJ indices cannot be zero")

  if result < 0 or result >= vertexCount:
    raise newException(
      ViewerObjError,
      "OBJ face index is out of range: " & value
    )

proc parseFaceVertex(token: string, vertexCount: int): int =
  ## Parses the position index from an OBJ face vertex token.
  let slash = token.find('/')
  let indexToken =
    if slash >= 0:
      token[0 ..< slash]
    else:
      token
  parseObjIndex(indexToken, vertexCount)

proc normalizeSafe(v, fallback: Vec3): Vec3 =
  ## Normalizes a vector or returns a fallback when degenerate.
  if v.length() <= 0.000001'f32:
    fallback
  else:
    v.normalize()

proc loadObjMesh(path: string): ObjMesh =
  ## Loads a simple OBJ mesh and expands it into a triangle list.
  if not fileExists(path):
    raise newException(ViewerObjError, "OBJ file not found: " & path)

  var
    positions: seq[Vec3]
    triangles: seq[array[3, int]]

  for rawLine in readFile(path).splitLines():
    let line = rawLine.strip()
    if line.len == 0 or line[0] == '#':
      continue

    let parts = strutils.splitWhitespace(line)
    case parts[0]
    of "v":
      if parts.len < 4:
        raise newException(ViewerObjError, "OBJ vertex line is incomplete")
      positions.add(
        vec3(
          parseFloat32(parts[1]),
          parseFloat32(parts[2]),
          parseFloat32(parts[3])
        )
      )
    of "f":
      if parts.len < 4:
        raise newException(ViewerObjError, "OBJ face line is incomplete")
      var faceIndices: seq[int]
      for i in 1 ..< parts.len:
        faceIndices.add(parseFaceVertex(parts[i], positions.len))
      for i in 1 ..< faceIndices.len - 1:
        triangles.add([faceIndices[0], faceIndices[i], faceIndices[i + 1]])
    else:
      discard

  if positions.len == 0:
    raise newException(ViewerObjError, "OBJ does not contain any vertices")
  if triangles.len == 0:
    raise newException(ViewerObjError, "OBJ does not contain any faces")

  var
    minPos = positions[0]
    maxPos = positions[0]
  for i in 1 ..< positions.len:
    let p = positions[i]
    minPos.x = min(minPos.x, p.x)
    minPos.y = min(minPos.y, p.y)
    minPos.z = min(minPos.z, p.z)
    maxPos.x = max(maxPos.x, p.x)
    maxPos.y = max(maxPos.y, p.y)
    maxPos.z = max(maxPos.z, p.z)

  let
    center = (minPos + maxPos) * 0.5'f32
    size = maxPos - minPos
    maxExtent = max(size.x, max(size.y, size.z))
  if maxExtent <= 0.0'f32:
    raise newException(ViewerObjError, "OBJ bounds are degenerate")

  let uniformScale = 2.0'f32 / maxExtent
  var normalizedPositions = newSeq[Vec3](positions.len)
  for i, p in positions:
    normalizedPositions[i] = (p - center) * uniformScale

  var smoothedNormals = newSeq[Vec3](normalizedPositions.len)
  for tri in triangles:
    let
      a = normalizedPositions[tri[0]]
      b = normalizedPositions[tri[1]]
      c = normalizedPositions[tri[2]]
      faceNormal = normalizeSafe(
        (b - a).cross(c - a),
        vec3(0.0'f32, 1.0'f32, 0.0'f32)
      )
    smoothedNormals[tri[0]] += faceNormal
    smoothedNormals[tri[1]] += faceNormal
    smoothedNormals[tri[2]] += faceNormal

  result.vertices = newSeq[ObjVertex](triangles.len * 3)
  var vertexIndex = 0
  for tri in triangles:
    for idx in tri:
      result.vertices[vertexIndex] = ObjVertex(
        position: normalizedPositions[idx].toFloatArray(),
        normal: normalizeSafe(
          smoothedNormals[idx],
          vec3(0.0'f32, 1.0'f32, 0.0'f32)
        ).toFloatArray()
      )
      inc vertexIndex

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
  renderer: var ObjRenderer,
  mesh: ObjMesh
) =
  ## Creates the pipeline state and depth resources.
  const ShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct ObjVertex {
  packed_float3 position;
  packed_float3 normal;
};

struct Uniforms {
  float4x4 mvp;
  float4x4 model;
};

struct VertexOut {
  float4 position [[position]];
  float3 normal;
};

vertex VertexOut vertexMain(
  uint vertexId [[vertex_id]],
  constant ObjVertex *vertices [[buffer(0)]],
  constant Uniforms &uniforms [[buffer(1)]]
) {
  VertexOut out;
  float4 position = float4(float3(vertices[vertexId].position), 1.0);
  out.position = uniforms.mvp * position;
  out.normal = normalize((uniforms.model * float4(
    float3(vertices[vertexId].normal),
    0.0
  )).xyz);
  return out;
}

fragment float4 fragmentMain(VertexOut in [[stage_in]]) {
  float3 lightDir = normalize(float3(0.4, 0.8, 0.5));
  float diffuse = abs(dot(normalize(in.normal), lightDir));
  float light = 0.2 + diffuse * 0.8;
  float3 baseColor = float3(0.88, 0.84, 0.78);
  return float4(baseColor * light, 1.0);
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

  renderer.depthTexture = createDepthTexture(device, width, height)
  renderer.depthWidth = width
  renderer.depthHeight = height
  renderer.vertexBuffer = device.newBufferWithBytes(
    unsafeAddr mesh.vertices[0],
    (mesh.vertices.len * sizeof(ObjVertex)).uint,
    0
  )
  checkNil(renderer.vertexBuffer, "Could not create a vertex buffer")
  renderer.vertexCount = mesh.vertices.len.uint

proc updateCamera(camera: var CameraState, window: Window) =
  ## Updates the orbit camera from mouse drag and scroll wheel input.
  if window.buttonDown[MouseLeft]:
    let delta = window.mouseDelta
    camera.yaw += delta.x.float32 * RotateScale
    camera.pitch = clamp(
      camera.pitch + delta.y.float32 * RotateScale,
      MinPitch,
      MaxPitch
    )

  if window.buttonDown[MouseRight]:
    let delta = window.mouseDelta
    camera.distance = clamp(
      camera.distance + delta.y.float32 * DragZoomScale,
      MinDistance,
      MaxDistance
    )

  let scroll = window.scrollDelta
  if scroll.y != 0.0'f32:
    camera.distance = clamp(
      camera.distance - scroll.y.float32 * ZoomScale,
      MinDistance,
      MaxDistance
    )

proc updateTransform(
  renderer: var ObjRenderer,
  camera: CameraState,
  aspect: float32
) =
  ## Updates the view and projection constants for the current frame.
  let
    cosPitch = cos(camera.pitch)
    eye = vec3(
      sin(camera.yaw) * cosPitch * camera.distance,
      sin(camera.pitch) * camera.distance,
      cos(camera.yaw) * cosPitch * camera.distance
    )
    target = vec3(0.0'f32, 0.0'f32, 0.0'f32)
    model = mat4()
    baseAngles = toAngles(eye, target)
    cameraAngles = vec3(baseAngles.x, baseAngles.y, 0.0'f32)
    view = inverse(translate(eye) * fromAngles(cameraAngles))
    proj = perspectiveMetal(60.0'f32.toRadians, aspect, 0.1'f32, 100.0'f32)
    mvp = proj * view * model
  renderer.uniforms.mvp = mat4ToArray(mvp)
  renderer.uniforms.model = mat4ToArray(model)

proc recordModel(
  window: Window,
  commandQueue: MTLCommandQueue,
  device: MTLDevice,
  view: NSView,
  layer: CAMetalLayer,
  renderer: var ObjRenderer
) =
  ## Records the draw commands for the bunny mesh.
  autoreleasepool:
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
    encoder.setCullMode(MTLCullModeNone)
    encoder.setDepthStencilState(renderer.depthState)
    encoder.setVertexBuffer(renderer.vertexBuffer, 0, 0)
    encoder.setVertexBytes(
      unsafeAddr renderer.uniforms,
      sizeof(renderer.uniforms).uint,
      1
    )
    encoder.drawPrimitives(
      MTLPrimitiveTypeTriangle,
      0,
      renderer.vertexCount
    )
    encoder.endEncoding()
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()

proc main() =
  ## Opens a Windy window and draws the Stanford bunny.
  let window = newWindow(
    "Metal Bunny Viewer",
    ivec2(Width.int32, Height.int32)
  )

  let mesh = loadObjMesh(objPath())

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

  var renderer: ObjRenderer
  initRenderer(device, Width, Height, renderer, mesh)

  var camera = CameraState(
    yaw: 0.0'f32,
    pitch: 0.15'f32,
    distance: 2.8'f32
  )

  while not window.closeRequested:
    pollEvents()
    updateCamera(camera, window)
    let
      bounds = view.bounds
      backing = view.convertRectToBacking(bounds)
      aspect = max(1.0, backing.size.width) / max(1.0, backing.size.height)
    updateTransform(renderer, camera, aspect)
    recordModel(window, commandQueue, device, view, layer, renderer)

main()
