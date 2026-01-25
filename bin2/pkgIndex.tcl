package ifneeded tools 1.0 \
    [list source [file join $dir tools.tcl]]
package ifneeded packages 1.0 \
    [list source [file join $dir packages.tcl]]
package ifneeded dots 1.0 \
    [list source [file join $dir dots.tcl]]
package ifneeded sddm 1.0 \
    [list source [file join $dir sddm.tcl]]
