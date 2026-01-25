import std/[strutils, options]
import ast

{.push gcsafe.}

proc parse*(input: string): Script

proc skipInlineWhitespace(input: string, pos: var int) =
  ## Skip spaces, tabs, and carriage returns. NOT newlines (which are command terminators)
  while pos < input.len and input[pos] in {' ', '\t', '\r'}:
    pos += 1

proc skipWhitespaceAndComments(input: string, pos: var int) =
  while pos < input.len:
    if input[pos] in Whitespace:
      pos += 1
    elif input[pos] == '#':
      while pos < input.len and input[pos] != '\n':
        pos += 1
    else:
      break

proc parseLiteral(input: string, pos: var int,
                  stopChars: set[char]): WordPart =
  var text = ""
  while pos < input.len and input[pos] notin stopChars:
    text.add(input[pos])
    pos += 1
  return WordPart(kind: Literal, text: text)

proc parseVarSubst(input: string, pos: var int): WordPart =
  pos += 1

  var varName = ""

  if pos < input.len and (input[pos].isAlphaNumeric or input[pos] == '_'):
    while pos < input.len and
          (input[pos].isAlphaNumeric or input[pos] == '_'):
      varName.add(input[pos])
      pos += 1

  elif pos < input.len and input[pos] == '{':
    pos += 1
    while pos < input.len and input[pos] != '}':
      varName.add(input[pos])
      pos += 1
    if pos < input.len: pos += 1

  result = WordPart(kind: VariableSubst, varName: varName)

  if pos < input.len and input[pos] in {'('}:
    inc pos
    let start = pos
    while true:
      if pos >= input.len:
        raise CatchableError.newException("Missing closing ')' starting at: " & $start)
      if input[pos] in {')'}:
        inc pos
        break
      inc pos
    assert(start != pos)
    let subStr = input[start ..< pos - 1]
    result.index = some(subStr)

proc parseCmdSubst(input: string, pos: var int): WordPart =
  pos += 1
  var depth = 1
  var scriptText = ""

  while pos < input.len and depth > 0:
    if input[pos] == '[':
      depth += 1
    elif input[pos] == ']':
      depth -= 1
      if depth == 0:
        break
    elif input[pos] == '\\' and pos + 1 < input.len:
      scriptText.add(input[pos])
      pos += 1
      scriptText.add(input[pos])
      pos += 1
      continue

    scriptText.add(input[pos])
    pos += 1

  if pos < input.len: pos += 1

  let nestedScript = parse(scriptText)
  return WordPart(kind: CommandSubst, script: nestedScript)

proc parseBackslash(input: string, pos: var int): WordPart

proc parseBareword(input: string, pos: var int, word: var Word) =
  let terminators = {' ', '\t', '\n', ';', '\r'}

  while pos < input.len and input[pos] notin terminators:
    case input[pos]:
      of '$':
        word.parts.add(parseVarSubst(input, pos))

      of '[':
        word.parts.add(parseCmdSubst(input, pos))

      of '\\':
        word.parts.add(parseBackslash(input, pos))

      else:
        word.parts.add(parseLiteral(input, pos,
                                    terminators + {'$', '[', '\\'}))

proc parseBackslash(input: string, pos: var int): WordPart =
  pos += 1

  if pos >= input.len:
    return WordPart(kind: Literal, text: "\\")

  let replacement = case input[pos]:
    of 'n': "\n"
    of 't': "\t"
    of 'r': "\r"
    of '\\': "\\"
    of '$': "$"
    of '[': "["
    of ']': "]"
    of '"': "\""
    of ' ': " "
    of '\n': ""
    else: "\\" & $input[pos]

  pos += 1
  return WordPart(kind: Literal, text: replacement)

proc parseQuotedWord(input: string, pos: var int, word: var Word) =
  pos += 1

  while pos < input.len:
    case input[pos]:
      of '"':
        pos += 1
        break

      of '$':
        word.parts.add(parseVarSubst(input, pos))

      of '[':
        word.parts.add(parseCmdSubst(input, pos))

      of '\\':
        word.parts.add(parseBackslash(input, pos))

      else:
        word.parts.add(parseLiteral(input, pos, {'"', '$', '[', '\\'}))

proc parseBracedWord(input: string, pos: var int): WordPart =
  pos += 1
  var depth = 1
  var text = ""

  while pos < input.len and depth > 0:
    case input[pos]:
      of '{':
        depth += 1
        text.add('{')
      of '}':
        depth -= 1
        if depth > 0:
          text.add('}')
      of '\\':
        if pos + 1 < input.len and input[pos + 1] in {'{', '}', '\\'}:
          text.add(input[pos + 1])
          pos += 1
        else:
          text.add('\\')
      else:
        text.add(input[pos])
    pos += 1

  return WordPart(kind: Literal, text: text)

proc parseWord(input: string, pos: var int): Word =
  var word = Word(parts: @[])
  let startChar = input[pos]

  case startChar:
    of '{':
      word.braced = true
      word.parts.add(parseBracedWord(input, pos))

    of '"':
      word.quoted = true
      parseQuotedWord(input, pos, word)

    else:
      parseBareword(input, pos, word)

  return word

proc parseCommand(input: string, pos: var int): Command =
  var command = Command(words: @[])

  while pos < input.len:
    skipInlineWhitespace(input, pos)

    if pos >= input.len or input[pos] in {'\n', ';'}:
      break

    let word = parseWord(input, pos)
    command.words.add(word)

  return command

proc skipCommandTerminator(input: string, pos: var int) =
  while pos < input.len and input[pos] in {' ', '\r'}:
    inc pos
  if pos < input.len and input[pos] in {'\n', ';'}:
    pos += 1

proc parse*(input: string): Script =
  echo "PARSING: ", input
  var pos = 0
  result = Script(commands: @[])
  while pos < input.len:
    skipWhitespaceAndComments(input, pos)
    if pos >= input.len:
      break
    let cmd = parseCommand(input, pos)
    result.commands.add(cmd)
    skipCommandTerminator(input, pos)
