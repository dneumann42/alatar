import std/[options, strutils]

type
  Script* = object
    commands*: seq[Command]

  Command* = object
    words*: seq[Word]

  Word* = object
    parts*: seq[WordPart]
    quoted*: bool
    braced*: bool

  WordPartKind* = enum
    Literal
    VariableSubst
    CommandSubst

  WordPart* = object
    case kind*: WordPartKind
    of Literal:
      text*: string
    of VariableSubst:
      varName*: string
      index*: Option[string]
    of CommandSubst:
      script*: Script

proc getLiteral*(command: Command): string =
  command.words[0].parts[0].text

proc toNumber*(command: Command): float64 =
  (try: command.getLiteral().parseFloat() except: 0.0)
