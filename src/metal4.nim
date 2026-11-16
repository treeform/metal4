# Auto-generated from vendored Apple headers — do not edit manually.
# Regenerate with: nim r tools/generate_api.nim

when not (defined(macosx) or defined(ios)):
  {.error: "metal4 only runs on macOS and iOS.".}

import metal4/[constants, types, functions, protocols]
export constants, types, functions, protocols

import metal4/[codes, runtime, extras, context]
export codes, runtime, extras, context
