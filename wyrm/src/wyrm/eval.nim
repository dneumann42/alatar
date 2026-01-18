import std/[tables, strutils]
import ast

type
  EvalCode* = enum
    Ok, Error, Return, Break, Continue

  EvalResult* = tuple[code: EvalCode, value: string]

  Interp* = ref object
    variables*: Table[string, string]
    commands*: Table[string, CommandProc]

  CommandProc* = proc(interp: Interp, args: seq[string]): EvalResult

proc init*(T: typedesc[Interp]): T =
  result = T()

proc evaluate*(interp: Interp, script: Script): EvalResult

proc cmdContinue(interp: Interp, args: seq[string]): EvalResult =
  if args.len != 0:
    return (Error, "wrong # args: should be \"continue\"")
  return (Continue, "")

proc cmdBreak(interp: Interp, args: seq[string]): EvalResult =
  if args.len != 0:
    return (Error, "wrong # args: should be \"break\"")
  return (Break, "")

proc cmdReturn(interp: Interp, args: seq[string]): EvalResult =
  if args.len > 1:
    return (Error, "wrong # args: should be \"return ?value?\"")
  if args.len == 1:
    return (Return, args[0])
  return (Return, "")

proc cmdSet(interp: Interp, args: seq[string]): EvalResult =
  if args.len < 1 or args.len > 2:
    return (Error, "wrong # args: should be \"set varName ?value?\"")

  let varName = args[0]
  if args.len == 2:
    interp.variables[varName] = args[1]
    return (Ok, args[1])
  else:
    if interp.variables.hasKey(varName):
      return (Ok, interp.variables[varName])
    else:
      return (Error, "can't read \"" & varName & "\": no such variable")

proc cmdUnset(interp: Interp, args: seq[string]): EvalResult =
  if args.len < 1:
    return (Error, "wrong # args: should be \"unset varName ?varName ...?\"")
  for varName in args:
    interp.variables.del(varName)
  return (Ok, "")

proc cmdInfo(interp: Interp, args: seq[string]): EvalResult =
  if args.len < 1:
    return (Error, "wrong # args: should be \"info subcommand ?arg ...?\"")

  case args[0]:
    of "exists":
      if args.len != 2:
        return (Error, "wrong # args: should be \"info exists varName\"")
      if interp.variables.hasKey(args[1]):
        return (Ok, "1")
      else:
        return (Ok, "0")
    of "vars":
      var names: seq[string] = @[]
      for k in interp.variables.keys:
        names.add(k)
      return (Ok, names.join(" "))
    of "commands":
      var names: seq[string] = @[]
      for k in interp.commands.keys:
        names.add(k)
      return (Ok, names.join(" "))
    else:
      return (Error, "unknown or ambiguous subcommand \"" & args[0] & "\"")

proc loadPrelude*(interp: Interp) =
  interp.commands["set"] = cmdSet
  interp.commands["unset"] = cmdUnset
  interp.commands["continue"] = cmdContinue
  interp.commands["break"] = cmdBreak
  interp.commands["return"] = cmdReturn
  interp.commands["info"] = cmdInfo

proc evaluateWord*(interp: Interp, word: Word): string =
  if word.braced:
    return word.parts[0].text

  var res = ""
  for part in word.parts:
    case part.kind:
      of Literal:
        res.add(part.text)
      of VariableSubst:
        if interp.variables.hasKey(part.varName):
          res.add(interp.variables[part.varName])
        else:
          raise newException(ValueError, "can't read \"" & part.varName & "\": no such variable")
      of CommandSubst:
        let (code, value) = interp.evaluate(part.script)
        if code == Error:
          raise newException(ValueError, value)
        res.add(value)

  return res

proc evaluate*(interp: Interp, cmd: Command): EvalResult =
  if cmd.words.len == 0:
    return (Ok, "")

  var args: seq[string] = @[]
  try:
    for word in cmd.words:
      args.add(interp.evaluateWord(word))
  except ValueError as e:
    return (Error, e.msg)

  let cmdName = args[0]
  let cmdArgs = args[1..^1]

  if not interp.commands.hasKey(cmdName):
    return (Error, "invalid command name \"" & cmdName & "\"")

  let cmdProc = interp.commands[cmdName]
  return cmdProc(interp, cmdArgs)

proc evaluate*(interp: Interp, script: Script): EvalResult =
  var lastResult: EvalResult = (Ok, "")

  for cmd in script.commands:
    lastResult = interp.evaluate(cmd)

    case lastResult.code:
      of Ok:
        continue
      of Error, Return:
        return lastResult
      of Break, Continue:
        return lastResult

  return lastResult
