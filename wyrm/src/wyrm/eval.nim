import std/[tables, strutils, math, strformat, options, sequtils]
import ast, reader, pretty

type
  EvalCode* = enum
    Ok, Error, Return, Break, Continue

  EvalResult* = tuple[code: EvalCode, value: string]

  Environment* = object
    scopes: seq[Table[string, string]]

  Evaluator* = ref object
    environment*: Environment
    commands*: Table[string, CommandProc]

  CommandProc* = proc(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.}

proc pushLevel*(evaluator: Evaluator) =
  evaluator.environment.scopes.add(initTable[string, string]())

proc popLevel*(evaluator: Evaluator): Table[string, string] =
  evaluator.environment.scopes.pop()

proc findVar*(evaluator: Evaluator, ident: string): Option[string] =
  if evaluator.environment.scopes.len == 0:
    return
  for scope in evaluator.environment.scopes:
    if scope.hasKey(ident):
      return some(scope[ident])

proc unsetVar*(evaluator: Evaluator, ident: string) =
  if evaluator.environment.scopes.len == 0:
    return
  for scope in evaluator.environment.scopes.mitems:
    if scope.hasKey(ident):
      scope.del(ident)
      return
 
proc setVar*(evaluator: Evaluator, ident: string, value: string) =
  evaluator.environment.scopes[^1][ident] = value

type
  TokenKind = enum
    tkNumber, tkVariable, tkPlus, tkMinus, tkStar, tkSlash, tkPercent, tkPower,
    tkLParen, tkRParen, tkEq, tkNe, tkLt, tkGt, tkLe, tkGe,
    tkAnd, tkOr, tkNot, tkEof, tkError

  Token = object
    kind: TokenKind
    value: float
    varName: string
    error: string

  ExprParser = object
    input: string
    pos: int
    current: Token
    evaluator: Evaluator

proc isTruthy(v: string): bool = v != "" and v != "0"

proc skipWhitespace(p: var ExprParser) =
  while p.pos < p.input.len and p.input[p.pos] in {' ', '\t', '\n', '\r'}:
    inc p.pos

proc nextToken(p: var ExprParser): Token =
  p.skipWhitespace()

  if p.pos >= p.input.len:
    return Token(kind: tkEof)

  let c = p.input[p.pos]

  # Numbers
  if c.isDigit or (c == '.' and p.pos + 1 < p.input.len and p.input[p.pos + 1].isDigit):
    var numStr = ""
    while p.pos < p.input.len and (p.input[p.pos].isDigit or p.input[p.pos] == '.'):
      numStr.add(p.input[p.pos])
      inc p.pos
    try:
      return Token(kind: tkNumber, value: parseFloat(numStr))
    except ValueError:
      return Token(kind: tkError, error: "invalid number: " & numStr)

  # Variables: $name or ${name}
  if c == '$':
    inc p.pos
    var varName = ""
    if p.pos < p.input.len and p.input[p.pos] == '{':
      # ${name} syntax
      inc p.pos
      while p.pos < p.input.len and p.input[p.pos] != '}':
        varName.add(p.input[p.pos])
        inc p.pos
      if p.pos < p.input.len:
        inc p.pos  # skip }
    else:
      # $name syntax
      while p.pos < p.input.len and (p.input[p.pos].isAlphaNumeric or p.input[p.pos] == '_'):
        varName.add(p.input[p.pos])
        inc p.pos
    return Token(kind: tkVariable, varName: varName)

  # Two-character operators
  if p.pos + 1 < p.input.len:
    let twoChar = p.input[p.pos..p.pos+1]
    case twoChar:
      of "**":
        p.pos += 2
        return Token(kind: tkPower)
      of "==":
        p.pos += 2
        return Token(kind: tkEq)
      of "!=":
        p.pos += 2
        return Token(kind: tkNe)
      of "<=":
        p.pos += 2
        return Token(kind: tkLe)
      of ">=":
        p.pos += 2
        return Token(kind: tkGe)
      of "&&":
        p.pos += 2
        return Token(kind: tkAnd)
      of "||":
        p.pos += 2
        return Token(kind: tkOr)
      else:
        discard

  # Single-character operators
  inc p.pos
  case c:
    of '+': return Token(kind: tkPlus)
    of '-': return Token(kind: tkMinus)
    of '*': return Token(kind: tkStar)
    of '/': return Token(kind: tkSlash)
    of '%': return Token(kind: tkPercent)
    of '(': return Token(kind: tkLParen)
    of ')': return Token(kind: tkRParen)
    of '<': return Token(kind: tkLt)
    of '>': return Token(kind: tkGt)
    of '!': return Token(kind: tkNot)
    else:
      return Token(kind: tkError, error: "unexpected character: " & c)

proc advance(p: var ExprParser) =
  p.current = p.nextToken()

proc prefixPrecedence(kind: TokenKind): int =
  case kind:
    of tkMinus, tkPlus, tkNot: 70
    else: 0

proc infixPrecedence(kind: TokenKind): (int, int) =
  # Returns (left binding power, right binding power)
  # Higher = binds tighter. Left < Right = left associative
  case kind:
    of tkOr: (10, 11)
    of tkAnd: (20, 21)
    of tkEq, tkNe: (30, 31)
    of tkLt, tkGt, tkLe, tkGe: (40, 41)
    of tkPlus, tkMinus: (50, 51)
    of tkStar, tkSlash, tkPercent: (60, 61)
    of tkPower: (81, 80)  # Right associative
    else: (0, 0)

proc parseExpr(p: var ExprParser, minBp: int = 0): (float, string) {.gcsafe.}

proc parsePrefix(p: var ExprParser): (float, string) {.gcsafe.} =
  let tok = p.current

  case tok.kind:
    of tkNumber:
      p.advance()
      return (tok.value, "")

    of tkVariable:
      p.advance()
      if p.evaluator.isNil:
        return (0, "no evaluatorreter for variable lookup")
      if p.evaluator.findVar(tok.varName).isNone:
        return (0, "can't read \"" & tok.varName & "\": no such variable")
      let varValue = p.evaluator.findVar(tok.varName).get()
      try:
        return (parseFloat(varValue), "")
      except ValueError:
        return (0, "variable \"" & tok.varName & "\" is not a number: " & varValue)

    of tkLParen:
      p.advance()
      let (value, err) = p.parseExpr(0)
      if err != "":
        return (0, err)
      if p.current.kind != tkRParen:
        return (0, "expected ')'")
      p.advance()
      return (value, "")

    of tkMinus:
      p.advance()
      let (value, err) = p.parseExpr(prefixPrecedence(tkMinus))
      if err != "":
        return (0, err)
      return (-value, "")

    of tkPlus:
      p.advance()
      let (value, err) = p.parseExpr(prefixPrecedence(tkPlus))
      if err != "":
        return (0, err)
      return (value, "")

    of tkNot:
      p.advance()
      let (value, err) = p.parseExpr(prefixPrecedence(tkNot))
      if err != "":
        return (0, err)
      let notVal = if value == 0: 1.0 else: 0.0
      return (notVal, "")

    of tkEof:
      return (0, "unexpected end of expression")

    of tkError:
      return (0, tok.error)

    else:
      return (0, "unexpected token")

proc parseExpr(p: var ExprParser, minBp: int = 0): (float, string) {.gcsafe.} =
  var (left, err) = p.parsePrefix()
  if err != "":
    return (0, err)

  while true:
    let op = p.current.kind
    let (lbp, rbp) = infixPrecedence(op)

    if lbp == 0 or lbp < minBp:
      break

    p.advance()
    let (right, rightErr) = p.parseExpr(rbp)
    if rightErr != "":
      return (0, rightErr)

    case op:
      of tkPlus: left = left + right
      of tkMinus: left = left - right
      of tkStar: left = left * right
      of tkSlash:
        if right == 0:
          return (0, "division by zero")
        left = left / right
      of tkPercent:
        if right == 0:
          return (0, "modulo by zero")
        left = left.int.float mod right.int.float
      of tkPower: left = pow(left, right)
      of tkEq: left = if left == right: 1.0 else: 0.0
      of tkNe: left = if left != right: 1.0 else: 0.0
      of tkLt: left = if left < right: 1.0 else: 0.0
      of tkGt: left = if left > right: 1.0 else: 0.0
      of tkLe: left = if left <= right: 1.0 else: 0.0
      of tkGe: left = if left >= right: 1.0 else: 0.0
      of tkAnd: left = if left != 0 and right != 0: 1.0 else: 0.0
      of tkOr: left = if left != 0 or right != 0: 1.0 else: 0.0
      else:
        break

  return (left, "")

proc evalExpr*(evaluator: Evaluator, expr: string): (float, string) {.gcsafe.} =
  var parser = ExprParser(input: expr, pos: 0, evaluator: evaluator)
  parser.advance()
  let (value, err) = parser.parseExpr(0)
  if err != "":
    return (0, err)
  if parser.current.kind != tkEof:
    return (0, "unexpected token after expression")
  return (value, "")

proc cmdExpr(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len != 1:
    return (Error, "wrong # args: should be \"@ expression\"")

  let (value, err) = evaluator.evalExpr(args[0])
  if err != "":
    return (Error, err)

  # Format: remove trailing .0 for integers
  let intVal = value.int
  if value == intVal.float:
    return (Ok, $intVal)
  else:
    return (Ok, $value)

proc init*(T: typedesc[Evaluator]): T =
  result = T(
    environment: Environment(scopes: @[])
  )
  result.pushLevel()

proc evaluate*(evaluator: Evaluator, script: Script): EvalResult {.gcsafe.}

proc cmdContinue(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len != 0:
    return (Error, "wrong # args: should be \"continue\"")
  return (Continue, "")

proc cmdBreak(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len != 0:
    return (Error, "wrong # args: should be \"break\"")
  return (Break, "")

proc cmdReturn(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len > 1:
    return (Error, "wrong # args: should be \"return ?value?\"")
  if args.len == 1:
    return (Return, args[0])
  return (Return, "")

proc cmdSet(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len < 1 or args.len > 2:
    return (Error, "wrong # args: should be \"set varName ?value?\"")

  let varName = args[0]
  if args.len == 2:
    evaluator.setVar(varName, args[1])
    return (Ok, args[1])
  else:
    if evaluator.findVar(varName).isSome:
      return (Ok, evaluator.findVar(varName).get())
    else:
      return (Error, "can't read \"" & varName & "\": no such variable")

proc cmdUnset(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len < 1:
    return (Error, "wrong # args: should be \"unset varName ?varName ...?\"")
  for varName in args:
    evaluator.unsetVar(varName)
  return (Ok, "")

proc cmdInfo(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  if args.len < 1:
    return (Error, "wrong # args: should be \"info subcommand ?arg ...?\"")

  case args[0]:
    of "exists":
      if args.len != 2:
        return (Error, "wrong # args: should be \"info exists varName\"")
      if evaluator.findVar(args[1]).isSome:
        return (Ok, "1")
      else:
        return (Ok, "0")
    of "vars":
      var names: seq[string] = @[]
      for scope in evaluator.environment.scopes:
        names.add(scope.pairs.toSeq().join("|"))
      return (Ok, names.join("\n"))
    of "commands":
      var names: seq[string] = @[]
      for k in evaluator.commands.keys:
        names.add(k)
      return (Ok, names.join(" "))
    else:
      return (Error, "unknown or ambiguous subcommand \"" & args[0] & "\"")

proc cmdPuts(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  var file: File = stdout
  if args[0] == "-out" and args[1] == "stdout":
    file = stdout
  if args[0] == "-out" and args[1] == "stderr":
    file = stderr
  for str in args:
    file.write(str)
  file.writeLine("")

proc cmdInc(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  return (Ok, $(args[0].parseInt + 1))

proc cmdIf(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  let exp = args[0]
  let (code, value) = evaluator.evaluate(parse exp)
  if code == Error:
    return (Error, value)
  if args.len > 1 and code == Ok and value.isTruthy:
    return evaluator.evaluate(parse args[1])
  var
    index = 2
  while index < args.len:
    if args[index] != "elif":
      break
    inc index
    let (expCode, expValue) = evaluator.evaluate(parse args[index])
    if expCode == Ok and expValue.isTruthy:
      return evaluator.evaluate(parse args[index + 1])
    index += 2
  if args.len > 2 and args[^2] == "else":
    return evaluator.evaluate(parse args[^1])
  return (Error, "Unexpected expression in if")

proc cmdFun(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  let name = args[0]
  evaluator.commands[name] = proc(e: Evaluator, subArgs: seq[string]): EvalResult {.gcsafe.} =
    let a = parse(args[1])
    for i in 0 ..< a.commands[0].words.len:
      let ident = a.commands[0].words[i]
      evaluator.setVar(ident.parts[0].text, subArgs[i])
    return e.evaluate(parse args[^1])

proc cmdEval(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  return evaluator.evaluate(parse args[^1])

proc cmdWhile(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.} =
  while true:
    let (code, value) = evaluator.evaluate(parse args[0])
    if code != Ok:
      return (code, value)
    if not value.isTruthy:
      break
    result = evaluator.evaluate(parse args[1])
    if result.code != Ok:
      return

proc setCommand(evaluator: Evaluator, name: string, fn: proc(evaluator: Evaluator, args: seq[string]): EvalResult {.gcsafe.}) =
  evaluator.commands[name] = fn

const PreludeScript = staticRead"prelude.wyrm"

proc loadPrelude*(evaluator: Evaluator) =
  template set(id, cmd) = evaluator.setCommand(id, cmd)
  set "set", cmdSet
  set "puts", cmdPuts
  set "inc", cmdInc
  set "unset", cmdUnset
  set "continue", cmdContinue
  set "break", cmdBreak
  set "return", cmdReturn
  set "info", cmdInfo
  set "@", cmdExpr
  set "if", cmdIf
  set "fun", cmdFun
  set "eval", cmdEval
  set "while", cmdWhile
  echo "[Loading prelude]"
  echo evaluator.evaluate(parse PreludeScript)
  
proc evaluateWord*(evaluator: Evaluator, word: Word): string =
  if word.braced:
    return word.parts[0].text

  var res = ""
  for part in word.parts:
    case part.kind:
      of Literal:
        res.add(part.text)
      of VariableSubst:
        if evaluator.findVar(part.varName).isSome:
          res.add(evaluator.findVar(part.varName).get())
        else:
          raise newException(ValueError, "can't read \"" & part.varName & "\": no such variable")
      of CommandSubst:
        let (code, value) = evaluator.evaluate(part.script)
        if code == Error:
          raise newException(ValueError, value)
        res.add(value)

  return res

proc evaluate*(evaluator: Evaluator, cmd: Command): EvalResult {.gcsafe.} =
  if cmd.words.len == 0:
    return (Ok, "")

  var args: seq[string] = @[]
  try:
    for word in cmd.words:
      args.add(evaluator.evaluateWord(word))
  except ValueError as e:
    return (Error, e.msg)

  let cmdName = args[0]
  let cmdArgs = args[1..^1]

  if not evaluator.commands.hasKey(cmdName):
    try:
      discard parseFloat(cmdName)
      return (Ok, cmdName)
    except:
      discard
    return (Error, &"Invalid command: {cmdName}")

  let cmdProc = evaluator.commands[cmdName]
  evaluator.pushLevel()
  result = cmdProc(evaluator, cmdArgs)
  discard evaluator.popLevel()

proc evaluate*(evaluator: Evaluator, script: Script): EvalResult {.gcsafe.} =
  var lastResult: EvalResult = (Ok, "")

  for cmd in script.commands:
    lastResult = evaluator.evaluate(cmd)

    case lastResult.code:
      of Ok:
        continue
      of Error, Return:
        return lastResult
      of Break, Continue:
        return lastResult

  return lastResult
