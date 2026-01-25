import std/[unittest, strutils, tables, options]
import wyrm
import wyrm/eval

proc newEvaluator(): Evaluator =
  result = Evaluator.init()
  result.loadPrelude()

proc eval(code: string): EvalResult =
  var interp = newEvaluator()
  interp.evaluate(parse(code))

proc evalWith(interp: Evaluator, code: string): EvalResult =
  interp.evaluate(parse(code))

suite "Basic Evaluation":
  test "empty script":
    let (code, value) = eval("")
    check code == Ok
    check value == ""

  test "unknown command":
    let (code, value) = eval("unknown")
    check code == Error
    check "Invalid command" in value

  test "comment only":
    let (code, value) = eval("# just a comment")
    check code == Ok

suite "set Command":
  test "set variable":
    let (code, value) = eval("set x hello")
    check code == Ok
    check value == "hello"

  test "set and get variable":
    var interp = newEvaluator()
    discard interp.evalWith("set x 42")
    let (code, value) = interp.evalWith("set x")
    check code == Ok
    check value == "42"

  test "set overwrites variable":
    var interp = newEvaluator()
    discard interp.evalWith("set x first")
    discard interp.evalWith("set x second")
    let (code, value) = interp.evalWith("set x")
    check code == Ok
    check value == "second"

  test "get nonexistent variable":
    let (code, value) = eval("set nonexistent")
    check code == Error
    check "no such variable" in value

  test "set with no args":
    let (code, value) = eval("set")
    check code == Error
    check "wrong # args" in value

  test "set with too many args":
    let (code, value) = eval("set a b c")
    check code == Error
    check "wrong # args" in value

suite "unset Command":
  test "unset variable":
    var interp = newEvaluator()
    discard interp.evalWith("set x 123")
    let (code, _) = interp.evalWith("unset x")
    check code == Ok
    let (code2, value2) = interp.evalWith("set x")
    check code2 == Error
    check "no such variable" in value2

  test "unset multiple variables":
    var interp = newEvaluator()
    discard interp.evalWith("set a 1")
    discard interp.evalWith("set b 2")
    discard interp.evalWith("set c 3")
    discard interp.evalWith("unset a c")
    check interp.evalWith("set b").code == Ok
    check interp.evalWith("set a").code == Error
    check interp.evalWith("set c").code == Error

  test "unset nonexistent variable":
    let (code, _) = eval("unset nonexistent")
    check code == Ok

  test "unset no args":
    let (code, _) = eval("unset")
    check code == Error
    check "wrong # args" in eval("unset").value

suite "info Command":
  test "info exists - true":
    var interp = newEvaluator()
    discard interp.evalWith("set x 123")
    let (code, value) = interp.evalWith("info exists x")
    check code == Ok
    check value == "1"

  test "info exists - false":
    let (code, value) = eval("info exists nonexistent")
    check code == Ok
    check value == "0"

  test "info vars":
    var interp = newEvaluator()
    discard interp.evalWith("set a 1")
    discard interp.evalWith("set b 2")
    let (code, value) = interp.evalWith("info vars")
    check code == Ok
    check "a" in value
    check "b" in value

  test "info commands":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("info commands")
    check code == Ok
    check "set" in value
    check "info" in value

  test "info unknown subcommand":
    let (code, value) = eval("info unknown")
    check code == Error
    check "unknown or ambiguous subcommand" in value

  test "info no args":
    let (code, _) = eval("info")
    check code == Error

suite "Control Flow - return":
  test "return with value":
    let (code, value) = eval("return hello")
    check code == Return
    check value == "hello"

  test "return without value":
    let (code, value) = eval("return")
    check code == Return
    check value == ""

  test "return stops script":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x before; return early; set x after")
    check code == Return
    check value == "early"
    check interp.evalWith("set x").value == "before"

  test "return too many args":
    let (code, _) = eval("return a b")
    check code == Error

suite "Control Flow - break":
  test "break":
    let (code, value) = eval("break")
    check code == Break
    check value == ""

  test "break with args":
    let (code, _) = eval("break arg")
    check code == Error

suite "Control Flow - continue":
  test "continue":
    let (code, value) = eval("continue")
    check code == Continue
    check value == ""

  test "continue with args":
    let (code, _) = eval("continue arg")
    check code == Error

suite "Variable Substitution":
  test "simple variable substitution":
    var interp = newEvaluator()
    discard interp.evalWith("set name World")
    let (code, value) = interp.evalWith("set greeting Hello$name")
    check code == Ok
    check value == "HelloWorld"

  test "variable in quoted string":
    var interp = newEvaluator()
    discard interp.evalWith("set name World")
    let (code, value) = interp.evalWith("set greeting \"Hello $name\"")
    check code == Ok
    check value == "Hello World"

  test "braced variable":
    var interp = newEvaluator()
    discard interp.evalWith("set name World")
    let (code, value) = interp.evalWith("set greeting \"Hello ${name}!\"")
    check code == Ok
    check value == "Hello World!"

  test "no substitution in braces":
    var interp = newEvaluator()
    discard interp.evalWith("set name World")
    let (code, value) = interp.evalWith("set literal {$name}")
    check code == Ok
    check value == "$name"

  test "undefined variable error":
    let (code, value) = eval("set x $undefined")
    check code == Error
    check "no such variable" in value

  test "multiple variables":
    var interp = newEvaluator()
    discard interp.evalWith("set a Hello")
    discard interp.evalWith("set b World")
    let (code, value) = interp.evalWith("set c \"$a $b\"")
    check code == Ok
    check value == "Hello World"

suite "Command Substitution":
  test "simple command substitution":
    var interp = newEvaluator()
    discard interp.evalWith("set x [set y 42]")
    check interp.evalWith("set x").value == "42"
    check interp.evalWith("set y").value == "42"

  test "nested command substitution":
    var interp = newEvaluator()
    discard interp.evalWith("set inner 123")
    let (code, value) = interp.evalWith("set outer [set result [set inner]]")
    check code == Ok
    check value == "123"

  test "command substitution in quotes":
    var interp = newEvaluator()
    discard interp.evalWith("set x 42")
    let (code, value) = interp.evalWith("set msg \"Value is [set x]\"")
    check code == Ok
    check value == "Value is 42"

  test "command substitution error propagates":
    let (code, value) = eval("set x [set undefined]")
    check code == Error

  test "multiple command substitutions":
    var interp = newEvaluator()
    discard interp.evalWith("set a 1")
    discard interp.evalWith("set b 2")
    let (code, value) = interp.evalWith("set c \"[set a] and [set b]\"")
    check code == Ok
    check value == "1 and 2"

suite "Multiple Commands":
  test "semicolon separated":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set a 1; set b 2; set c 3")
    check code == Ok
    check value == "3"
    check interp.evalWith("set a").value == "1"
    check interp.evalWith("set b").value == "2"

  test "newline separated":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set a 1\nset b 2\nset c 3")
    check code == Ok
    check value == "3"

  test "error stops execution":
    var interp = newEvaluator()
    discard interp.evalWith("set x before")
    let (code, _) = interp.evalWith("set x middle; unknown_cmd; set x after")
    check code == Error
    check interp.evalWith("set x").value == "middle"

suite "Edge Cases":
  test "empty command":
    let (code, _) = eval(";")
    check code == Ok

  test "multiple semicolons":
    let (code, _) = eval(";;;")
    check code == Ok

  test "whitespace only":
    let (code, _) = eval("   \t\n   ")
    check code == Ok

  test "quoted empty string":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x \"\"")
    check code == Ok
    check value == ""

  test "braced empty string":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x {}")
    check code == Ok
    check value == ""

  test "variable with underscore":
    var interp = newEvaluator()
    discard interp.evalWith("set my_var 123")
    check interp.evalWith("set my_var").value == "123"

  test "variable with numbers":
    var interp = newEvaluator()
    discard interp.evalWith("set var123 abc")
    check interp.evalWith("set var123").value == "abc"

suite "Quoting and Escaping":
  test "escaped dollar in quotes":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x \"\\$literal\"")
    check code == Ok
    check value == "$literal"

  test "escaped bracket in quotes":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x \"\\[not a command\\]\"")
    check code == Ok
    check value == "[not a command]"

  test "backslash n in quotes":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x \"line1\\nline2\"")
    check code == Ok
    check value == "line1\nline2"

  test "braces preserve everything":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x {$var [cmd] \\n}")
    check code == Ok
    check value == "$var [cmd] \\n"

  test "nested braces":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("set x {outer {inner} outer}")
    check code == Ok
    check value == "outer {inner} outer"

suite "Custom Commands":
  test "register and call custom command":
    var interp = newEvaluator()
    interp.commands["double"] = proc(i: Evaluator, args: seq[string]): EvalResult =
      if args.len != 1:
        return (Error, "wrong # args")
      return (Ok, args[0] & args[0])

    let (code, value) = interp.evalWith("double hello")
    check code == Ok
    check value == "hellohello"

  test "custom command can access variables":
    var interp = newEvaluator()
    interp.commands["getvar"] = proc(i: Evaluator, args: seq[string]): EvalResult =
      if i.findVar("secret").isSome:
        return (Ok, i.findVar("secret").get())
      return (Error, "no secret")

    discard interp.evalWith("set secret 42")
    let (code, value) = interp.evalWith("getvar")
    check code == Ok
    check value == "42"

  test "custom command can set variables":
    var interp = newEvaluator()
    interp.commands["setmagic"] = proc(i: Evaluator, args: seq[string]): EvalResult =
      i.setVar("magic", "abracadabra")
      return (Ok, "done")

    discard interp.evalWith("setmagic")
    check interp.evalWith("set magic").value == "abracadabra"

suite "Function Scoping":
  test "function parameters shadow outer variables":
    var interp = newEvaluator()
    discard interp.evalWith("set n 1")
    discard interp.evalWith("fun test {n} { set result $n }")
    discard interp.evalWith("test 42")
    # Parameter n=42 should have been used inside function
    # but outer n should still be 1
    check interp.evalWith("set n").value == "1"

  test "function can modify outer variable":
    var interp = newEvaluator()
    discard interp.evalWith("set x outer")
    discard interp.evalWith("fun modify {} { set x inner }")
    discard interp.evalWith("modify")
    # set updates existing variable in outer scope
    check interp.evalWith("set x").value == "inner"

  test "function can read outer variable":
    var interp = newEvaluator()
    discard interp.evalWith("set outer_val 123")
    discard interp.evalWith("fun reader {} { set outer_val }")
    let (code, value) = interp.evalWith("reader")
    check code == Ok
    check value == "123"

  test "new variable in function is local":
    var interp = newEvaluator()
    discard interp.evalWith("fun creator {} { set local_var 42 }")
    discard interp.evalWith("creator")
    # local_var was created in function scope and is gone after function returns
    let (code, _) = interp.evalWith("set local_var")
    check code == Error

  test "nested function scopes":
    var interp = newEvaluator()
    discard interp.evalWith("set x 1")
    discard interp.evalWith("fun outer {} { set x 2; inner }")
    discard interp.evalWith("fun inner {} { set x 3 }")
    discard interp.evalWith("outer")
    # Both inner and outer modify the same global x
    check interp.evalWith("set x").value == "3"

  test "function return value":
    var interp = newEvaluator()
    discard interp.evalWith("fun add {a b} { @ {$a + $b} }")
    let (code, value) = interp.evalWith("add 3 4")
    check code == Ok
    check value == "7"

  test "while loop preserves outer scope":
    var interp = newEvaluator()
    discard interp.evalWith("set i 0; set sum 0")
    discard interp.evalWith("while {@ {$i < 3}} { set sum [@ {$sum + $i}]; set i [@ {$i + 1}] }")
    check interp.evalWith("set sum").value == "3"
    check interp.evalWith("set i").value == "3"

  test "dotimes function from prelude":
    var interp = newEvaluator()
    discard interp.evalWith("set total 0")
    discard interp.evalWith("dotimes 5 { set total [@ {$total + 1}] }")
    check interp.evalWith("set total").value == "5"

  test "parameter shadows outer but inner set reads parameter":
    var interp = newEvaluator()
    discard interp.evalWith("set val global")
    discard interp.evalWith("fun shadow {val} { set val }")
    let (code, value) = interp.evalWith("shadow local")
    check code == Ok
    check value == "local"
    # Global unchanged because parameter shadowed it
    check interp.evalWith("set val").value == "global"

  test "parameter modification stays local":
    var interp = newEvaluator()
    discard interp.evalWith("set x 100")
    discard interp.evalWith("fun modify_param {x} { set x [@ {$x + 1}]; set x }")
    let (code, value) = interp.evalWith("modify_param 5")
    check code == Ok
    check value == "6"
    # Global x unchanged because parameter x shadows it
    check interp.evalWith("set x").value == "100"

suite "Recursion":
  test "can compute factorials":
    var evaluator = newEvaluator()
    let (_, value) = evaluator.evaluate(parse """
      fun factorial {n} {
        if {[@ { $n < 2 }]} {
          1
        } else {
          set v [factorial [@ { $n - 1 }]]
          @ { $n * $v }
        }
    }
    factorial 5
    """)
    check value == "120"

suite "Indexing":
  test "can index with literal":
    var interp = newEvaluator()
    discard interp.evalWith("set xs {a b c d}")
    let (code, value) = interp.evalWith("set result $xs(0)")
    check code == Ok
    check value == "a"

  test "can index with variable":
    var interp = newEvaluator()
    discard interp.evalWith("set xs {a b c d}")
    discard interp.evalWith("set i 2")
    let (code, value) = interp.evalWith("set result $xs($i)")
    check code == Ok
    check value == "c"

  test "can index with negative index":
    var interp = newEvaluator()
    discard interp.evalWith("set xs {a b c d}")
    let (code, value) = interp.evalWith("set result $xs(-1)")
    check code == Ok
    check value == "d"

  test "index out of bounds returns error":
    var interp = newEvaluator()
    discard interp.evalWith("set xs {a b c}")
    let (code, value) = interp.evalWith("set result $xs(10)")
    check code == Error
    check "out of bounds" in value

  test "can use isIndexable helper":
    check isIndexable("a b c") == true
    check isIndexable("single") == false
    check isIndexable("") == false

suite "Function argc/argv":
  test "argc is preserved across nested commands":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("""
      fun countArgs {} {
        set result ""
        set i 0
        while {@ {$i < $argc}} {
          set result "$result $i"
          set i [@ {$i + 1}]
        }
        set result
      }
      countArgs a b c d
    """)
    check code == Ok
    check value.strip() == "0 1 2 3"

  test "argv contains all arguments":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("""
      fun getArgs {} {
        set argv
      }
      getArgs one two three
    """)
    check code == Ok
    check value == "one\ttwo\tthree"  # Tab-separated to preserve argument boundaries

  test "key_values iterates correctly over argv":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("""
      fun testKv {} {
        set result ""
        key_values $argv {
          set result "$result|$k:$v"
        }
        set result
      }
      testKv a 1 b 2
    """)
    check code == Ok
    check value == "|a:1|b:2"

  test "argv indexing works correctly":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("""
      fun testIdx {} {
        set r0 $argv(0)
        set r1 $argv(1)
        set r2 $argv(2)
        set r3 $argv(3)
        set result "$r0|$r1|$r2|$r3"
      }
      testIdx a b c d
    """)
    check code == Ok
    check value == "a|b|c|d"

  test "length of argv matches argc":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("""
      fun testLen {} {
        set len [length $argv]
        set result "$argc=$len"
      }
      testLen a b c d
    """)
    check code == Ok
    check value == "4=4"

  test "key_values with multi-word arguments":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("""
      fun testKv {} {
        set result ""
        key_values $argv {
          set result "$result|$k:$v"
        }
        set result
      }
      testKv title: " DEV " maxsize: {320 256}
    """)
    check code == Ok
    check value == "|title:: DEV |maxsize::320 256"

  test "key_values with line continuation":
    var interp = newEvaluator()
    let (code, value) = interp.evalWith("fun testKv {} {\n  set result \"\"\n  key_values $argv {\n    set result \"$result|$k:$v\"\n  }\n  set result\n}\ntestKv \\\n  title: \" DEV \" \\\n  maxsize: {320 256}")
    check code == Ok
    check value == "|title:: DEV |maxsize::320 256"
