import
  std/json

type
  EnumValueDef* = object
    name*: string
    value*: string

  EnumDef* = object
    name*: string
    baseType*: string
    isOptions*: bool
    values*: seq[EnumValueDef]

  FieldDef* = object
    name*: string
    typ*: string

  StructDef* = object
    name*: string
    fields*: seq[FieldDef]

  PropertyDef* = object
    owner*: string
    name*: string
    typ*: string
    getterName*: string
    readonly*: bool

  MethodParamDef* = object
    label*: string
    name*: string
    typ*: string

  MethodDef* = object
    owner*: string
    name*: string
    selector*: string
    returnType*: string
    params*: seq[MethodParamDef]
    isClassMethod*: bool

  HandleDef* = object
    name*: string
    kind*: string
    baseName*: string

  AliasDef* = object
    name*: string
    targetType*: string

  FunctionDef* = object
    name*: string
    returnType*: string
    params*: seq[FieldDef]

  HeaderIr* = object
    enums*: seq[EnumDef]
    structs*: seq[StructDef]
    handles*: seq[HandleDef]
    aliases*: seq[AliasDef]
    properties*: seq[PropertyDef]
    methods*: seq[MethodDef]
    functions*: seq[FunctionDef]

proc toJson*(value: EnumValueDef): JsonNode =
  ## Converts an enum value definition to JSON.
  %*{
    "name": value.name,
    "value": value.value
  }

proc toJson*(value: EnumDef): JsonNode =
  ## Converts an enum definition to JSON.
  result = %*{
    "name": value.name,
    "baseType": value.baseType,
    "isOptions": value.isOptions
  }
  result["values"] = newJArray()
  for item in value.values:
    result["values"].add(item.toJson())

proc toJson*(value: FieldDef): JsonNode =
  ## Converts a field definition to JSON.
  %*{
    "name": value.name,
    "typ": value.typ
  }

proc toJson*(value: StructDef): JsonNode =
  ## Converts a struct definition to JSON.
  result = %*{
    "name": value.name
  }
  result["fields"] = newJArray()
  for item in value.fields:
    result["fields"].add(item.toJson())

proc toJson*(value: PropertyDef): JsonNode =
  ## Converts a property definition to JSON.
  %*{
    "owner": value.owner,
    "name": value.name,
    "typ": value.typ,
    "getterName": value.getterName,
    "readonly": value.readonly
  }

proc toJson*(value: MethodParamDef): JsonNode =
  ## Converts a method parameter definition to JSON.
  %*{
    "label": value.label,
    "name": value.name,
    "typ": value.typ
  }

proc toJson*(value: MethodDef): JsonNode =
  ## Converts a method definition to JSON.
  result = %*{
    "owner": value.owner,
    "name": value.name,
    "selector": value.selector,
    "returnType": value.returnType,
    "isClassMethod": value.isClassMethod
  }
  result["params"] = newJArray()
  for item in value.params:
    result["params"].add(item.toJson())

proc toJson*(value: HandleDef): JsonNode =
  ## Converts a handle definition to JSON.
  %*{
    "name": value.name,
    "kind": value.kind,
    "baseName": value.baseName
  }

proc toJson*(value: AliasDef): JsonNode =
  ## Converts a type alias definition to JSON.
  %*{
    "name": value.name,
    "targetType": value.targetType
  }

proc toJson*(value: FunctionDef): JsonNode =
  ## Converts a function definition to JSON.
  result = %*{
    "name": value.name,
    "returnType": value.returnType
  }
  result["params"] = newJArray()
  for item in value.params:
    result["params"].add(item.toJson())

proc toJson*(value: HeaderIr): JsonNode =
  ## Converts the full header IR to JSON.
  result = newJObject()
  result["enums"] = newJArray()
  result["structs"] = newJArray()
  result["handles"] = newJArray()
  result["aliases"] = newJArray()
  result["properties"] = newJArray()
  result["methods"] = newJArray()
  result["functions"] = newJArray()

  for item in value.enums:
    result["enums"].add(item.toJson())
  for item in value.structs:
    result["structs"].add(item.toJson())
  for item in value.handles:
    result["handles"].add(item.toJson())
  for item in value.aliases:
    result["aliases"].add(item.toJson())
  for item in value.properties:
    result["properties"].add(item.toJson())
  for item in value.methods:
    result["methods"].add(item.toJson())
  for item in value.functions:
    result["functions"].add(item.toJson())
