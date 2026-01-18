import wyrm/[ast, reader, eval]
export ast, reader, eval

when isMainModule:
  import std/tables
  import pretty

  var interp = Interp.init()
  interp.loadPrelude()
  print interp.evaluate(parse("set x 123"))
  print interp
