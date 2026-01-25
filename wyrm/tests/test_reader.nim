import std/unittest
import wyrm

suite "Basic Parsing":
  test "simple command":
    let script = parse("puts hello")
    check script.commands.len == 1
    check script.commands[0].words.len == 2
    check script.commands[0].words[0].parts[0].text == "puts"
    check script.commands[0].words[1].parts[0].text == "hello"

  test "command with multiple words":
    let script = parse("set x 42")
    check script.commands.len == 1
    check script.commands[0].words.len == 3
    check script.commands[0].words[0].parts[0].text == "set"
    check script.commands[0].words[1].parts[0].text == "x"
    check script.commands[0].words[2].parts[0].text == "42"

suite "Multiple Commands":
  test "commands separated by newline":
    let script = parse("puts hello\nputs world")
    check script.commands.len == 2
    check script.commands[0].words[0].parts[0].text == "puts"
    check script.commands[0].words[1].parts[0].text == "hello"
    check script.commands[1].words[0].parts[0].text == "puts"
    check script.commands[1].words[1].parts[0].text == "world"

  test "commands separated by semicolon":
    let script = parse("puts hello; puts world")
    check script.commands.len == 2
    check script.commands[0].words[1].parts[0].text == "hello"
    check script.commands[1].words[1].parts[0].text == "world"

  test "mixed newlines and semicolons":
    let script = parse("set a 1; set b 2\nset c 3")
    check script.commands.len == 3

suite "Variable Substitution":
  test "simple variable":
    let script = parse("puts $name")
    check script.commands[0].words[1].parts[0].kind == VariableSubst
    check script.commands[0].words[1].parts[0].varName == "name"

  test "braced variable":
    let script = parse("puts ${name}")
    check script.commands[0].words[1].parts[0].kind == VariableSubst
    check script.commands[0].words[1].parts[0].varName == "name"

  test "variable in middle of word":
    let script = parse("puts hello$name")
    check script.commands[0].words[1].parts.len == 2
    check script.commands[0].words[1].parts[0].kind == Literal
    check script.commands[0].words[1].parts[0].text == "hello"
    check script.commands[0].words[1].parts[1].kind == VariableSubst
    check script.commands[0].words[1].parts[1].varName == "name"

  test "multiple variables in word":
    let script = parse("puts $first$second")
    check script.commands[0].words[1].parts.len == 2
    check script.commands[0].words[1].parts[0].varName == "first"
    check script.commands[0].words[1].parts[1].varName == "second"

suite "Command Substitution":
  test "simple command substitution":
    let script = parse("puts [expr 1]")
    check script.commands[0].words[1].parts[0].kind == CommandSubst
    let nested = script.commands[0].words[1].parts[0].script
    check nested.commands[0].words[0].parts[0].text == "expr"

  test "nested command substitution":
    let script = parse("puts [string length [lindex $list 0]]")
    check script.commands[0].words[1].parts[0].kind == CommandSubst
    let outer = script.commands[0].words[1].parts[0].script
    check outer.commands[0].words[0].parts[0].text == "string"
    check outer.commands[0].words[2].parts[0].kind == CommandSubst

  test "command substitution in bareword":
    let script = parse("puts prefix[expr 1]suffix")
    check script.commands[0].words[1].parts.len == 3
    check script.commands[0].words[1].parts[0].kind == Literal
    check script.commands[0].words[1].parts[0].text == "prefix"
    check script.commands[0].words[1].parts[1].kind == CommandSubst
    check script.commands[0].words[1].parts[2].kind == Literal
    check script.commands[0].words[1].parts[2].text == "suffix"

suite "Quoted Words":
  test "simple quoted word":
    let script = parse("puts \"hello world\"")
    check script.commands[0].words.len == 2
    check script.commands[0].words[1].quoted == true
    check script.commands[0].words[1].parts[0].text == "hello world"

  test "quoted word with variable":
    let script = parse("puts \"hello $name\"")
    check script.commands[0].words[1].quoted == true
    check script.commands[0].words[1].parts.len == 2
    check script.commands[0].words[1].parts[0].text == "hello "
    check script.commands[0].words[1].parts[1].kind == VariableSubst
    check script.commands[0].words[1].parts[1].varName == "name"

  test "quoted word with command substitution":
    let script = parse("puts \"result: [expr 1+1]\"")
    check script.commands[0].words[1].parts.len == 2
    check script.commands[0].words[1].parts[0].text == "result: "
    check script.commands[0].words[1].parts[1].kind == CommandSubst

suite "Braced Words":
  test "simple braced word":
    let script = parse("puts {hello world}")
    check script.commands[0].words[1].braced == true
    check script.commands[0].words[1].parts[0].text == "hello world"

  test "braced word with no substitution":
    let script = parse("puts {$name [expr 1]}")
    check script.commands[0].words[1].braced == true
    check script.commands[0].words[1].parts[0].kind == Literal
    check script.commands[0].words[1].parts[0].text == "$name [expr 1]"

  test "nested braces":
    let script = parse("puts {outer {inner} outer}")
    check script.commands[0].words[1].parts[0].text == "outer {inner} outer"

  test "deeply nested braces":
    let script = parse("puts {a {b {c} b} a}")
    check script.commands[0].words[1].parts[0].text == "a {b {c} b} a"

suite "Backslash Substitution":
  test "backslash newline":
    let script = parse("puts hello\\nworld")
    check script.commands[0].words[1].parts.len == 3
    check script.commands[0].words[1].parts[0].text == "hello"
    check script.commands[0].words[1].parts[1].text == "\n"
    check script.commands[0].words[1].parts[2].text == "world"

  test "escaped dollar":
    let script = parse("puts \\$notavar")
    check script.commands[0].words[1].parts[0].kind == Literal
    check script.commands[0].words[1].parts[0].text == "$"

  test "escaped bracket":
    let script = parse("puts \\[notcmd\\]")
    check script.commands[0].words[1].parts[0].text == "["
    check script.commands[0].words[1].parts[2].text == "]"

  test "line continuation":
    let script = parse("puts hello\\\nworld")
    check script.commands.len == 1
    check script.commands[0].words.len == 2

suite "Comments":
  test "comment line":
    let script = parse("# this is a comment\nputs hello")
    check script.commands.len == 1
    check script.commands[0].words[0].parts[0].text == "puts"

  test "comment at start":
    let script = parse("# comment\n# another\nputs hi")
    check script.commands.len == 1

  test "hash in middle of command is not comment":
    let script = parse("puts hello#world")
    check script.commands[0].words[1].parts[0].text == "hello#world"

suite "Edge Cases":
  test "empty input":
    let script = parse("")
    check script.commands.len == 0

  test "only whitespace":
    let script = parse("   \n\t  ")
    check script.commands.len == 0

  test "only comments":
    let script = parse("# comment\n# another")
    check script.commands.len == 0

  test "trailing whitespace":
    let script = parse("puts hello   ")
    check script.commands.len == 1
    check script.commands[0].words.len == 2

  test "leading whitespace":
    let script = parse("   puts hello")
    check script.commands.len == 1
    check script.commands[0].words[0].parts[0].text == "puts"

  test "empty braces":
    let script = parse("puts {}")
    check script.commands[0].words[1].parts[0].text == ""

  test "empty quotes":
    let script = parse("puts \"\"")
    check script.commands[0].words[1].parts.len == 0

  test "multiple spaces between words":
    let script = parse("puts    hello    world")
    check script.commands[0].words.len == 3

suite "Complex Nested Structures":
  test "variable in command substitution":
    let script = parse("puts [string length $var]")
    let nested = script.commands[0].words[1].parts[0].script
    check nested.commands[0].words[2].parts[0].kind == VariableSubst
    check nested.commands[0].words[2].parts[0].varName == "var"

  test "if command with braced body":
    let script = parse("if {$x > 0} {puts positive}")
    check script.commands.len == 1
    check script.commands[0].words.len == 3
    check script.commands[0].words[1].braced == true
    check script.commands[0].words[2].braced == true

  test "proc definition":
    let script = parse("proc greet {name} {puts \"Hello $name\"}")
    check script.commands[0].words.len == 4
    check script.commands[0].words[0].parts[0].text == "proc"
    check script.commands[0].words[1].parts[0].text == "greet"

suite "Potential Bug Cases":
  test "bracket in bareword terminates correctly":
    let script = parse("[list a b]")
    check script.commands[0].words[0].parts[0].kind == CommandSubst
    let inner = script.commands[0].words[0].parts[0].script
    check inner.commands[0].words.len == 3

  test "newline should terminate command not be whitespace":
    let script = parse("set a 1\nset b 2")
    check script.commands.len == 2
    check script.commands[0].words.len == 3
    check script.commands[1].words.len == 3

  test "spaces around semicolon":
    let script = parse("set a 1 ; set b 2")
    check script.commands.len == 2

  test "carriage return handling":
    let script = parse("set a 1\r\nset b 2")
    check script.commands.len == 2

  test "tab as word separator":
    let script = parse("set\ta\t1")
    check script.commands[0].words.len == 3

  test "escaped brace in braced word":
    let script = parse("puts {hello \\} world}")
    check script.commands[0].words[1].parts[0].text == "hello } world"

  test "variable followed by non-alphanum":
    let script = parse("puts $x.txt")
    check script.commands[0].words[1].parts.len == 2
    check script.commands[0].words[1].parts[0].varName == "x"
    check script.commands[0].words[1].parts[1].text == ".txt"

  test "dollar at end of word":
    let script = parse("puts cost$")
    check script.commands[0].words[1].parts.len == 2
    check script.commands[0].words[1].parts[0].text == "cost"
    check script.commands[0].words[1].parts[1].varName == ""

  test "command substitution at word boundaries":
    let script = parse("[cmd1][cmd2]")
    check script.commands[0].words[0].parts.len == 2
    check script.commands[0].words[0].parts[0].kind == CommandSubst
    check script.commands[0].words[0].parts[1].kind == CommandSubst
