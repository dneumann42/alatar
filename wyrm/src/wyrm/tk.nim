import std/[strutils, macros]
import eval, reader, pretty, ast
import nimtk/all

proc pairA*(s: Script): Command =
  s.commands[0]

const TkScript = staticRead"tk.wyrm"

proc loadTk*(evaluator: var Evaluator) =
  var self: ref Evaluator
  new(self)
  self[] = evaluator
 
  template set(id: string, blk: untyped) =
    self[].setCommand(id) do (
      evaluator {.inject.}: Evaluator,
      args {.inject.}: seq[string]) -> EvalResult {.gcsafe.}:
      `blk`

  var tk = newTk()
  var root: ref Root
  new(root)
  root[] = tk.getRoot()

  set("set-title"):
    root[].title = args[0]
    (Ok, "")

  set("set-maxsize"):
    root[].maxsize = (
       args[0].parseInt,
       args[1].parseInt
    )
    (Ok, "")

  set("set-geometry"):
    root[].geometry = args[0]
    (Ok, "")

  set("tk"):
    for i in 0 ..< args.len:
      if args[i] == "mainloop":
        tk.mainloop()
    (Ok, "")

  set("bind"):
    {.cast(gcsafe).}:
      root[].bind(args[0]) do (ev: Event):
        discard evaluator.evaluate(parse args[1])
    (Ok, "")

  discard evaluator.evaluate(parse TkScript)
