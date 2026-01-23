#!/usr/bin/env tclsh

package provide tools 1.0

oo::class create Stringable {
    method to-string {{maxDepth 2}} {
        return [my Stringable::_ppObject [self] $maxDepth {} 0]
    }

    method Stringable::_ppObject {obj maxDepth seen indentLevel} {
        if {[lsearch -exact $seen $obj] >= 0} {
            return "<cycle:$obj>"
        }
        lappend seen $obj

        set cls [info object class $obj]
        set pad [string repeat "  " $indentLevel]

        # Collect instance vars (reflection)
        set vars [lsort -dictionary [info object vars $obj]]

        # Header
        if {[llength $vars] == 0} {
            return "${cls} {}"
        }

        # Depth limit: show only summary
        if {$indentLevel >= $maxDepth} {
            return "${cls} {…}"
        }

        set out "${cls} {\n"
        foreach v $vars {
            # Read instance var value safely
            set ok 1
            set val ""
            if {[catch {
                upvar 0 ${obj}::$v ref
                set val $ref
            }]} {
                set ok 0
            }

            if {!$ok} {
                append out "${pad}  $v = <unreadable>\n"
                continue
            }

            set rendered [my Stringable::_ppValue $val $maxDepth $seen [expr {$indentLevel + 1}]]
            append out "${pad}  $v = $rendered\n"
        }
        append out "${pad}}"
        return $out
    }

    method Stringable::_ppValue {val maxDepth seen indentLevel} {
	# TclOO object command?
	if {[info object isa object $val]} {
	    return [my Stringable::_ppObject $val $maxDepth $seen $indentLevel]
	}

	# If it parses as a list, we may want to treat it as a list first
	set llen -1
	if {![catch {llength $val} llen] && $llen > 1} {
	    set elems $val
	    foreach e $elems {
		if {[info object isa object $e]} {
		    return [my Stringable::_ppList $val $maxDepth $seen $indentLevel]
		}
	    }
	}

	set dsize -1
	if {![catch {dict size $val} dsize] && $dsize > 0} {
	    return [my Stringable::_ppDict $val $maxDepth $seen $indentLevel]
	}

	if {$llen > 1} {
	    return [my Stringable::_ppList $val $maxDepth $seen $indentLevel]
	}

	# Scalar
	return [my Stringable::_quote $val]
    }

    method Stringable::_ppDict {d maxDepth seen indentLevel} {
        set pad [string repeat "  " $indentLevel]
        if {$indentLevel >= $maxDepth} {
            return "{…}"
        }

        set keys [lsort -dictionary [dict keys $d]]
        if {[llength $keys] == 0} {
            return "{}"
        }

        set out "{\n"
        foreach k $keys {
            set v [dict get $d $k]
            set rv [my Stringable::_ppValue $v $maxDepth $seen [expr {$indentLevel + 1}]]
            append out "${pad}  [my Stringable::_quote $k] = $rv\n"
        }
        append out "[string repeat "  " [expr {$indentLevel - 1}]]}"
        return $out
    }

    method Stringable::_ppList {lst maxDepth seen indentLevel} {
        # Keep lists compact, but recurse into elements if needed
        if {$indentLevel >= $maxDepth} {
            return "\[ … \]"
        }

        set n [llength $lst]
        if {$n == 0} {
            return "\[\]"
        }

        # If it’s a “small simple list”, print inline, otherwise multi-line
        if {$n <= 6} {
            set parts {}
            foreach e $lst {
                lappend parts [my Stringable::_ppValue $e $maxDepth $seen $indentLevel]
            }
            return "\[ [join $parts {, }] \]"
        }

        set pad [string repeat "  " $indentLevel]
        set out "\[\n"
        foreach e $lst {
            set re [my Stringable::_ppValue $e $maxDepth $seen [expr {$indentLevel + 1}]]
            append out "${pad}  $re\n"
        }
        append out "[string repeat "  " [expr {$indentLevel - 1}]]]"
        return $out
    }

    method Stringable::_quote {s} {
        # Quote strings that contain whitespace or braces/brackets etc.
        if {[regexp {[ \t\r\n\{\}\[\]\$\\\";]} $s]} {
            return "\"[string map {\" \\\" \\ \\\\ \n \\n \t \\t \r \\r} $s]\""
        }
        return $s
    }
}

oo::class create Argument {
    mixin Stringable
    variable short-name name documentation
    constructor {s n {d ""}} {
	set short-name $s
	set name $n
	set documentation $d
    }
    method get-short-name {} { return $short-name }
    method get-name       {} { return $name }
    method get-doc        {} { return $documentation }
}

oo::class create ArgumentManager {
    variable args
    method find-by-name {name} {
	foreach arg $args {
	    if {[$arg get-name] eq $name} {
		return $arg
	    }
	}
    }
    method add-arg {arg} {
	# TODO: check for colliding name and short names
	lappend args $arg
    }
}

oo::class create Module {
    mixin Stringable ArgumentManager
    superclass Argument
    variable commands
    
    constructor {s n {d ""}} {
	next $s $n $d
	set commands {}
    }

    method invoke {args} {
	set cmd [my find-by-name [lindex $args 0]]
	if {$cmd ne ""} {
	    $cmd invoke [lrange $args 1 end]
	}
    }
}

oo::class create Command {
    mixin Stringable
    superclass Argument
    variable call
    
    constructor {s n c {d ""}} {
	next $s $n $d
	variable call
	set call $c
    }

    method invoke {args} {
	variable call
	{*}$call {*}$args
    }
}
