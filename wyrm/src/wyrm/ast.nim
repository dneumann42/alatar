import std/options

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
