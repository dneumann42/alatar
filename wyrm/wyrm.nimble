# Package

version       = "0.0.0"
author        = "dneumann"
description   = "A shell language"
license       = "MIT"
srcDir        = "src"
bin           = @["wyrm"]


# Dependencies

requires "nim >= 2.2.6"
requires "pretty"


# Tasks

task test, "Run tests":
  exec "nim c -o:tests/test_reader.out --path:src -r tests/test_reader.nim"
  exec "nim c -o:tests/test_eval.out --path:src -r tests/test_eval.nim"

task clean, "Remove build artifacts":
  exec "find . -type f -name '*.out' -delete"
