import foundations, codes

export foundations, codes

{.passL: "-framework Metal -framework QuartzCore".}

type
  CALayer* = distinct NSObject
