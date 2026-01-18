import wyrm/[ast, reader, eval]
export ast, reader, eval

when isMainModule:
  var evaluator = Evaluator.init()
  evaluator.loadPrelude()
  echo evaluator.evaluate(parse("""

  set i 0
  while {@ {$i < 10}} {
    puts $i
    set i [@ {$i + 1}]
  }

  """)).value
