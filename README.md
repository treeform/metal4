<img src="docs/metal4.png">

# metal4 - Metal 4 bindings for Nim.

`nimby install metal4`

![Github Actions](https://github.com/treeform/metal4/workflows/Github%20Actions/badge.svg)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/treeform/metal4)
![GitHub Repo stars](https://img.shields.io/github/stars/treeform/metal4)
![GitHub](https://img.shields.io/github/license/treeform/metal4)
![GitHub issues](https://img.shields.io/github/issues/treeform/metal4)

[API reference](https://treeform.github.io/metal4)

## About

`metal4` vendors Apple Metal SDK headers, parses a selected subset of the
Objective-C API, generates low-level Nim bindings, and layers a small
UFCS-friendly facade on top for examples and day-to-day use.

### Workflow

Regenerate the bindings with:

```text
nim r tools/download_headers.nim
nim r tools/generate_api.nim
nim check tests/tests.nim
nim r tests/tests.nim
```
