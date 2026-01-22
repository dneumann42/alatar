import std/[os]
import wyrm/[ast, reader, eval, tk]
export ast, reader, eval

const WyrmReplScript = staticRead"repl.wyrm"

when isMainModule:
  var evaluator = Evaluator.init()
  evaluator.loadPrelude()
  evaluator.loadTk()
  evaluator.scriptPath = currentSourcePath()
  echo evaluator.evaluate(parse(WyrmReplScript)).value
