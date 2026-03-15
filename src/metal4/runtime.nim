when not defined(macosx):
  {.error: "metal4 only runs on macOS.".}

import
  windy/platforms/macos/[macdefs, objc],
  codes

export macdefs, objc, codes

{.passL: "-framework Metal -framework QuartzCore".}

type
  CALayer* = distinct NSObject
