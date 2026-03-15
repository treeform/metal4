import
  std/[json, os, osproc, strutils, times]

const
  MetalHeaders = [
    "Metal.h",
    "MTLAllocation.h",
    "MTLBuffer.h",
    "MTLCommandBuffer.h",
    "MTLCommandEncoder.h",
    "MTLCommandQueue.h",
    "MTLDepthStencil.h",
    "MTLDevice.h",
    "MTLDrawable.h",
    "MTLFunctionDescriptor.h",
    "MTLLibrary.h",
    "MTLPixelFormat.h",
    "MTLRenderCommandEncoder.h",
    "MTLRenderPass.h",
    "MTLRenderPipeline.h",
    "MTLSampler.h",
    "MTLTexture.h",
    "MTLTypes.h"
  ]

  QuartzCoreHeaders = [
    "CAMetalLayer.h"
  ]

proc sdkPath(): string =
  ## Returns the active macOS SDK path.
  let envPath = getEnv("METAL4_SDK_PATH")
  if envPath.len > 0:
    return envPath

  result = execProcess("xcrun --sdk macosx --show-sdk-path").strip()
  if result.len == 0:
    raise newException(IOError, "Could not resolve the active macOS SDK path")

proc copyFrameworkHeaders(
  sdkRoot: string,
  framework: string,
  headerNames: openArray[string]
) =
  ## Copies selected framework headers into the vendored tree.
  let
    sourceRoot =
      sdkRoot /
      "System/Library/Frameworks" /
      framework /
      "Headers"
    targetRoot = currentSourcePath.parentDir / ".." / "headers" / framework

  createDir(targetRoot)

  for headerName in headerNames:
    let
      sourcePath = sourceRoot / headerName
      targetPath = targetRoot / headerName
    if not fileExists(sourcePath):
      raise newException(
        IOError,
        "Missing SDK header: " & sourcePath
      )
    copyFile(sourcePath, targetPath)

proc writeManifest(sdkRoot: string) =
  ## Writes the vendored header manifest.
  let
    outputPath =
      currentSourcePath.parentDir / ".." / "headers" / "manifest.json"
    manifest = %*{
      "sdkPath": sdkRoot,
      "downloadedAtUtc": now().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'"),
      "metalHeaders": MetalHeaders,
      "quartzCoreHeaders": QuartzCoreHeaders
    }
  writeFile(outputPath, manifest.pretty() & "\n")

proc main() =
  ## Copies the selected Metal 4 SDK headers into the repo.
  let resolvedSdk = sdkPath()

  createDir(currentSourcePath.parentDir / ".." / "headers")
  createDir(currentSourcePath.parentDir / ".." / "headers" / "Metal.framework")
  createDir(
    currentSourcePath.parentDir / ".." / "headers" / "QuartzCore.framework"
  )

  copyFrameworkHeaders(resolvedSdk, "Metal.framework", MetalHeaders)
  copyFrameworkHeaders(
    resolvedSdk,
    "QuartzCore.framework",
    QuartzCoreHeaders
  )
  writeManifest(resolvedSdk)

  echo "Vendored Metal headers from:"
  echo "  " & resolvedSdk

when isMainModule:
  main()
