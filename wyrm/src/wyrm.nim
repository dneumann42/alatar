import wyrm/[ast, reader, eval]
export ast, reader, eval

when isMainModule:
  var evaluator = Evaluator.init()
  evaluator.loadPrelude()
  echo evaluator.evaluate(parse("""

  set n 1
  puts "N: $n"
  fun factorial {n} {
    puts "N: $n"
  }
  factorial [@ {$n + 1}]
  puts "N2: $n"

  """)).value
