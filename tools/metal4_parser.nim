import
  std/[algorithm, os, strutils]

import metal4_ir

const
  MacroCalls = [
    "API_AVAILABLE",
    "API_UNAVAILABLE",
    "API_DEPRECATED",
    "API_DEPRECATED_WITH_REPLACEMENT",
    "NS_SWIFT_NAME",
    "NS_HEADER_AUDIT_BEGIN",
    "NS_HEADER_AUDIT_END",
    "CF_SWIFT_NAME"
  ]

  NoiseWords = [
    "MTL_EXPORT",
    "MTL_EXTERN",
    "MTL_INLINE",
    "NS_ASSUME_NONNULL_BEGIN",
    "NS_ASSUME_NONNULL_END",
    "NS_REFINED_FOR_SWIFT",
    "NS_RETURNS_RETAINED",
    "NS_RETURNS_INNER_POINTER",
    "NS_STRING_ENUM",
    "nullable",
    "nonnull",
    "_Nullable",
    "_Nonnull",
    "__nullable",
    "__nonnull",
    "__strong",
    "__weak",
    "__autoreleasing",
    "__kindof",
    "__unsafe_unretained",
    "oneway"
  ]

proc normalizeSpaces(text: string): string =
  ## Compacts mixed whitespace into a single-space representation.
  var prevSpace = false
  for ch in text:
    if ch in {' ', '\t', '\r', '\n'}:
      if not prevSpace:
        result.add(' ')
      prevSpace = true
    else:
      result.add(ch)
      prevSpace = false
  result = result.strip()

proc stripComments(text: string): string =
  ## Removes block and line comments from header text.
  var i = 0
  while i < text.len:
    if i + 1 < text.len and text[i] == '/' and text[i + 1] == '*':
      i += 2
      while i + 1 < text.len and not (text[i] == '*' and text[i + 1] == '/'):
        inc i
      i += 2
    elif i + 1 < text.len and text[i] == '/' and text[i + 1] == '/':
      while i < text.len and text[i] != '\n':
        inc i
    else:
      result.add(text[i])
      inc i

proc removeMacroCalls(text: string): string =
  ## Removes macro invocations with balanced parentheses.
  result = text
  for macroName in MacroCalls:
    var start = result.find(macroName & "(")
    while start >= 0:
      var depth = 0
      var i = start
      while i < result.len:
        if result[i] == '(':
          inc depth
        elif result[i] == ')':
          dec depth
          if depth == 0:
            inc i
            break
        inc i
      result = result[0 ..< start] & result[i .. ^1]
      start = result.find(macroName & "(")

proc removeNoiseWords(text: string): string =
  ## Removes standalone tokens that are not relevant to binding generation.
  result = text
  for word in NoiseWords:
    result = result.replace(" " & word & " ", " ")
    result = result.replace("\t" & word & " ", " ")
    result = result.replace(" " & word & "\t", " ")
    result = result.replace("(" & word & ")", "()")
    result = result.replace(" " & word & "*", " *")
    if result.startsWith(word & " "):
      result = result[word.len + 1 .. ^1]
    if result.endsWith(" " & word):
      result = result[0 ..< result.len - word.len - 1]
  result = normalizeSpaces(result)

proc cleanDecl(text: string): string =
  ## Normalizes a declaration for parser consumption.
  result = stripComments(text)
  result = removeMacroCalls(result)
  result = removeNoiseWords(result)
  result = result.replace("id <", "id<")
  result = result.replace("< ", "<")
  result = result.replace(" >", ">")
  result = result.replace(" *", "*")
  result = result.replace("*", " * ")
  result = normalizeSpaces(result)

proc splitTopLevel(text: string, separator: char): seq[string] =
  ## Splits text on a separator while tracking angle and paren depth.
  var
    current = ""
    parenDepth = 0
    angleDepth = 0
  for ch in text:
    if ch == '(':
      inc parenDepth
      current.add(ch)
    elif ch == ')':
      if parenDepth > 0:
        dec parenDepth
      current.add(ch)
    elif ch == '<':
      inc angleDepth
      current.add(ch)
    elif ch == '>':
      if angleDepth > 0:
        dec angleDepth
      current.add(ch)
    elif ch == separator:
      if parenDepth == 0 and angleDepth == 0:
        let item = current.strip()
        if item.len > 0:
          result.add(item)
        current.setLen(0)
      else:
        current.add(ch)
    else:
      current.add(ch)
  let item = current.strip()
  if item.len > 0:
    result.add(item)

proc lastIdentifierStart(text: string): int =
  ## Finds the start of the trailing identifier in a declaration.
  var i = text.len - 1
  while i >= 0 and text[i] in {' ', '\t'}:
    dec i
  while i >= 0 and (text[i].isAlphaNumeric or text[i] == '_'):
    dec i
  i + 1

proc splitTypeAndNames(text: string): tuple[typ: string, names: seq[string]] =
  ## Splits a field declaration into a type and one or more variable names.
  let cleaned = cleanDecl(text).strip(chars = {';'}).strip()
  if cleaned.len == 0:
    return

  let firstComma = cleaned.find(',')
  let pivot =
    if firstComma >= 0:
      cleaned[0 ..< firstComma]
    else:
      cleaned
  let nameStart = lastIdentifierStart(pivot)
  if nameStart <= 0 or nameStart >= pivot.len:
    return

  result.typ = pivot[0 ..< nameStart].strip()
  var namesText =
    if firstComma >= 0:
      pivot[nameStart .. ^1] & cleaned[firstComma .. ^1]
    else:
      pivot[nameStart .. ^1]
  for entry in namesText.split(','):
    let name = entry.replace("*", "").strip()
    if name.len > 0:
      result.names.add(name)

proc parseParams(text: string): seq[FieldDef] =
  ## Parses a C parameter list.
  for part in splitTopLevel(text, ','):
    let cleaned = cleanDecl(part)
    if cleaned == "void" or cleaned.len == 0:
      continue
    let split = splitTypeAndNames(cleaned)
    if split.names.len == 0:
      continue
    result.add(FieldDef(name: split.names[0], typ: split.typ))

proc addHandle(ir: var HeaderIr, handle: HandleDef) =
  ## Adds a handle if it is not already present.
  for i, existing in ir.handles:
    if existing.name == handle.name:
      if existing.baseName == "NSObject" and handle.baseName != "NSObject":
        ir.handles[i] = handle
      elif existing.kind != handle.kind:
        ir.handles[i] = handle
      return
  ir.handles.add(handle)

proc parseStructBlock(declText: string, ir: var HeaderIr) =
  ## Parses a typedef struct declaration block.
  let cleaned = declText.cleanDecl()
  let bodyStart = cleaned.find('{')
  let bodyEnd = cleaned.rfind('}')
  if bodyStart < 0 or bodyEnd < 0 or bodyEnd <= bodyStart:
    return

  let tail = cleaned[bodyEnd + 1 .. ^1].strip(chars = {';'}).strip()
  if tail.len == 0:
    return

  var item = StructDef(name: tail)
  for fieldDecl in cleaned[bodyStart + 1 ..< bodyEnd].split(';'):
    let split = splitTypeAndNames(fieldDecl)
    for name in split.names:
      item.fields.add(FieldDef(name: name, typ: split.typ))
  if item.fields.len > 0:
    ir.structs.add(item)

proc parseEnumBlock(declText: string, ir: var HeaderIr) =
  ## Parses an NS_ENUM or NS_OPTIONS declaration block.
  let cleaned = declText.cleanDecl()
  let kind =
    if "NS_OPTIONS" in cleaned:
      "NS_OPTIONS"
    else:
      "NS_ENUM"
  let macroStart = cleaned.find(kind & "(")
  if macroStart < 0:
    return
  let argsStart = cleaned.find('(', macroStart)
  let argsEnd = cleaned.find(')', argsStart)
  if argsStart < 0 or argsEnd < 0:
    return

  let args = splitTopLevel(cleaned[argsStart + 1 ..< argsEnd], ',')
  if args.len != 2:
    return

  let bodyStart = cleaned.find('{', argsEnd)
  let bodyEnd = cleaned.rfind('}')
  if bodyStart < 0 or bodyEnd < 0:
    return

  var item = EnumDef(
    name: args[1].strip(),
    baseType: args[0].strip(),
    isOptions: kind == "NS_OPTIONS"
  )

  for entry in splitTopLevel(cleaned[bodyStart + 1 ..< bodyEnd], ','):
    let line = entry.strip()
    if line.len == 0:
      continue
    let eq = line.find('=')
    if eq < 0:
      continue
    item.values.add(
      EnumValueDef(
        name: line[0 ..< eq].strip(),
        value: line[eq + 1 .. ^1].strip()
      )
    )
  if item.values.len > 0:
    ir.enums.add(item)

proc parseAliasDecl(decl: string, ir: var HeaderIr) =
  ## Parses a simple typedef alias.
  let cleaned = decl.cleanDecl().strip(chars = {';'}).strip()
  if not cleaned.startsWith("typedef "):
    return
  if "struct" in cleaned or "NS_ENUM" in cleaned or "NS_OPTIONS" in cleaned:
    return
  if "(" in cleaned or "^" in cleaned:
    return

  let rest = cleaned["typedef ".len .. ^1].strip()
  let nameStart = lastIdentifierStart(rest)
  if nameStart <= 0 or nameStart >= rest.len:
    return
  let
    aliasName = rest[nameStart .. ^1].strip()
    targetType = rest[0 ..< nameStart].strip()
  if aliasName.len > 0 and targetType.len > 0:
    ir.aliases.add(AliasDef(name: aliasName, targetType: targetType))

proc parseFunctionDecl(decl: string, ir: var HeaderIr) =
  ## Parses a free function declaration.
  let cleaned = decl.cleanDecl().strip(chars = {';'}).strip()
  let openParen = cleaned.find('(')
  let closeParen = cleaned.rfind(')')
  if openParen < 0 or closeParen < 0 or closeParen <= openParen:
    return

  var nameStart = openParen - 1
  while nameStart >= 0 and
      (cleaned[nameStart].isAlphaNumeric or cleaned[nameStart] == '_'):
    dec nameStart
  inc nameStart
  if nameStart >= openParen:
    return

  let
    name = cleaned[nameStart ..< openParen].strip()
    returnType = cleaned[0 ..< nameStart].strip()
    params = parseParams(cleaned[openParen + 1 ..< closeParen])
  if name.len > 0:
    ir.functions.add(
      FunctionDef(
        name: name,
        returnType: returnType,
        params: params
      )
    )

proc parsePropertyDecl(owner: string, decl: string, ir: var HeaderIr) =
  ## Parses an Objective-C property declaration.
  var cleaned = decl.cleanDecl().strip(chars = {';'}).strip()
  if not cleaned.startsWith("@property"):
    return
  cleaned = cleaned["@property".len .. ^1].strip()

  var
    readonly = false
    getterName = ""
  if cleaned.startsWith("("):
    let attrsEnd = cleaned.find(')')
    if attrsEnd >= 0:
      for attr in splitTopLevel(cleaned[1 ..< attrsEnd], ','):
        let item = attr.strip()
        if item == "readonly":
          readonly = true
        elif item.startsWith("getter ="):
          getterName = item["getter =".len .. ^1].strip()
      cleaned = cleaned[attrsEnd + 1 .. ^1].strip()

  let nameStart = lastIdentifierStart(cleaned)
  if nameStart <= 0 or nameStart >= cleaned.len:
    return

  let
    name = cleaned[nameStart .. ^1].replace("*", "").strip()
    typ = cleaned[0 ..< nameStart].strip()
  if getterName.len == 0:
    getterName = name

  ir.properties.add(
    PropertyDef(
      owner: owner,
      name: name,
      typ: typ,
      getterName: getterName,
      readonly: readonly
    )
  )

proc parseMethodDecl(owner: string, decl: string, ir: var HeaderIr) =
  ## Parses an Objective-C method declaration.
  let cleaned = decl.cleanDecl().strip(chars = {';'}).strip()
  if cleaned.len < 4 or (cleaned[0] != '-' and cleaned[0] != '+'):
    return

  var cursor = 1
  while cursor < cleaned.len and cleaned[cursor] in {' ', '\t'}:
    inc cursor
  if cursor >= cleaned.len or cleaned[cursor] != '(':
    return

  var depth = 1
  let returnStart = cursor + 1
  inc cursor
  while cursor < cleaned.len and depth > 0:
    if cleaned[cursor] == '(':
      inc depth
    elif cleaned[cursor] == ')':
      dec depth
    inc cursor
  if depth != 0:
    return

  let returnType = cleaned[returnStart ..< cursor - 1].strip()
  var rest = cleaned[cursor .. ^1].strip()
  if rest.len == 0:
    return

  var
    methodName = ""
    selector = ""
    params: seq[MethodParamDef]

  if ':' notin rest:
    methodName = rest
    selector = rest
  else:
    while rest.len > 0:
      let colon = rest.find(':')
      if colon < 0:
        break
      let label = rest[0 ..< colon].strip()
      selector.add(label & ":")
      if methodName.len == 0:
        methodName = label
      rest = rest[colon + 1 .. ^1].strip()
      if rest.len == 0 or rest[0] != '(':
        break

      depth = 1
      let typeStart = 1
      var typeEnd = 1
      while typeEnd < rest.len and depth > 0:
        if rest[typeEnd] == '(':
          inc depth
        elif rest[typeEnd] == ')':
          dec depth
        inc typeEnd
      if depth != 0:
        break

      let paramType = rest[typeStart ..< typeEnd - 1].strip()
      rest = rest[typeEnd .. ^1].strip()
      var nameEnd = 0
      while nameEnd < rest.len and
          (rest[nameEnd].isAlphaNumeric or rest[nameEnd] == '_'):
        inc nameEnd
      if nameEnd == 0:
        break
      let paramName = rest[0 ..< nameEnd]
      params.add(
        MethodParamDef(
          label: label,
          name: paramName,
          typ: paramType
        )
      )
      rest = rest[nameEnd .. ^1].strip()
    if methodName.len == 0:
      return
  ir.methods.add(
    MethodDef(
      owner: owner,
      name: methodName,
      selector: selector,
      returnType: returnType,
      params: params,
      isClassMethod: cleaned[0] == '+'
    )
  )

proc parseObjcBlock(lines: seq[string], start: int, ir: var HeaderIr): int =
  ## Parses an Objective-C @interface or @protocol block.
  let header = cleanDecl(lines[start].strip())
  let isInterface = header.startsWith("@interface ")

  var
    owner = ""
    baseName = "NSObject"

  if isInterface:
    let rest = header["@interface ".len .. ^1].strip()
    let colon = rest.find(':')
    if colon >= 0:
      owner = rest[0 ..< colon].strip()
      baseName = rest[colon + 1 .. ^1].strip()
    else:
      owner = rest
    addHandle(ir, HandleDef(name: owner, kind: "class", baseName: baseName))
  else:
    let rest = header["@protocol ".len .. ^1].strip()
    let angle = rest.find('<')
    owner =
      if angle >= 0:
        rest[0 ..< angle].strip()
      else:
        rest
    addHandle(ir, HandleDef(name: owner, kind: "protocol", baseName: "NSObject"))
  if owner.len == 0:
    return start

  var
    i = start + 1
    skipBraceDepth = 0
    current = ""
  while i < lines.len:
    let raw = lines[i].strip()
    let cleaned = cleanDecl(raw)
    if cleaned == "@end":
      break
    if cleaned.len == 0:
      inc i
      continue

    if skipBraceDepth > 0:
      for ch in cleaned:
        if ch == '{':
          inc skipBraceDepth
        elif ch == '}':
          dec skipBraceDepth
      inc i
      continue
    if cleaned == "{":
      skipBraceDepth = 1
      inc i
      continue

    if current.len == 0 and
        (cleaned.startsWith("@property") or
         cleaned.startsWith("-") or
         cleaned.startsWith("+")):
      current = raw
    elif current.len > 0:
      current.add(" " & raw)
    if current.len > 0 and ';' in raw:
      let decl = current
      current.setLen(0)
      if decl.strip().startsWith("@property"):
        parsePropertyDecl(owner, decl, ir)
      else:
        parseMethodDecl(owner, decl, ir)
    inc i
  i

proc parseForwardDecl(line: string, ir: var HeaderIr) =
  ## Parses @class and @protocol forward declarations.
  let cleaned = cleanDecl(line).strip(chars = {';'}).strip()
  if cleaned.startsWith("@class "):
    for name in cleaned["@class ".len .. ^1].split(','):
      let trimmed = name.strip()
      if trimmed.len > 0:
        addHandle(ir, HandleDef(name: trimmed, kind: "class", baseName: "NSObject"))
  elif cleaned.startsWith("@protocol ") and cleaned.endsWith(";") == false:
    discard
  elif cleaned.startsWith("@protocol "):
    for name in cleaned["@protocol ".len .. ^1].split(','):
      let trimmed = name.strip()
      if trimmed.len > 0:
        addHandle(
          ir,
          HandleDef(name: trimmed, kind: "protocol", baseName: "NSObject")
        )

proc parseHeaderText(text: string, ir: var HeaderIr) =
  ## Parses the contents of one vendored Objective-C header.
  let lines = stripComments(text).splitLines()
  var i = 0
  while i < lines.len:
    let line = lines[i].strip()
    if line.len == 0 or line.startsWith("#"):
      inc i
      continue

    if line.startsWith("typedef struct"):
      var declText = line
      inc i
      while i < lines.len:
        declText.add("\n" & lines[i])
        if '}' in lines[i] and ';' in lines[i]:
          break
        inc i
      parseStructBlock(declText, ir)
    elif line.startsWith("typedef NS_ENUM") or
        line.startsWith("typedef NS_OPTIONS"):
      var declText = line
      inc i
      while i < lines.len:
        declText.add("\n" & lines[i])
        if '}' in lines[i] and ';' in lines[i]:
          break
        inc i
      parseEnumBlock(declText, ir)
    elif line.startsWith("@interface ") or
        (line.startsWith("@protocol ") and not line.endsWith(";")):
      i = parseObjcBlock(lines, i, ir)
    elif line.startsWith("@class ") or line.startsWith("@protocol "):
      parseForwardDecl(line, ir)
    elif line.startsWith("typedef "):
      var declText = line
      while not declText.strip().endsWith(";") and i + 1 < lines.len:
        inc i
        declText.add(" " & lines[i].strip())
      parseAliasDecl(declText, ir)
    elif "MTLCreateSystemDefaultDevice(" in line:
      var declText = line
      while not declText.strip().endsWith(";") and i + 1 < lines.len:
        inc i
        declText.add(" " & lines[i].strip())
      parseFunctionDecl(declText, ir)
    inc i

proc vendoredHeaderPaths*(headersRoot: string): seq[string] =
  ## Returns vendored header paths in deterministic order.
  for path in walkDirRec(headersRoot):
    if path.endsWith(".h"):
      result.add(path)
  result.sort()

proc parseHeaders*(headersRoot: string): HeaderIr =
  ## Parses all vendored headers into a compact intermediate representation.
  for path in vendoredHeaderPaths(headersRoot):
    parseHeaderText(readFile(path), result)
