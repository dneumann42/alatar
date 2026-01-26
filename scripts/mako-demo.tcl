#!/usr/bin/env tclsh

# Mako notification demo
# Demonstrates all notification urgency levels and theme colors

proc send_notification {urgency title body {icon ""}} {
    set cmd [list notify-send -u $urgency]
    if {$icon ne ""} {
        lappend cmd -i $icon
    }
    lappend cmd $title $body

    if {[catch {exec {*}$cmd 2>@1} result]} {
        puts "ERROR: Failed to send notification: $result"
    }
}

puts "Mako Theme Demo - Sending notifications..."
puts "Watch your notifications area!\n"

# Low urgency notification
puts "1. Low urgency notification (gray border)"
send_notification low "Low Priority" "This is a low urgency notification\nIt will timeout in 3 seconds" "dialog-information"
after 1000

# Normal urgency notification
puts "2. Normal urgency notification (mauve border)"
send_notification normal "Normal Priority" "This is a normal urgency notification\nIt will timeout in 5 seconds" "dialog-information"
after 1000

# Critical urgency notification
puts "3. Critical urgency notification (red border)"
send_notification critical "Critical Alert!" "This is a critical notification\nIt won't timeout automatically" "dialog-warning"
after 1000

# Normal notification with different icons
puts "4. Info notification"
send_notification normal "Information" "Here's some useful information" "dialog-information"
after 1000

puts "5. Success notification"
send_notification normal "Success!" "Operation completed successfully" "emblem-default"
after 1000

puts "6. Warning notification"
send_notification normal "Warning" "Please pay attention to this" "dialog-warning"
after 1000

puts "7. Error notification"
send_notification normal "Error" "Something went wrong" "dialog-error"
after 1000

# Multiline notification
puts "8. Multiline notification"
send_notification normal "Multiline Test" "Line 1: This is the first line\nLine 2: This is the second line\nLine 3: This is the third line\nLine 4: Testing word wrap with longer text" "dialog-information"
after 1000

# Long title test
puts "9. Long title test"
send_notification normal "This is a very long notification title to test wrapping" "Body text here" "dialog-information"
after 1000

# Test with Ancient font rendering
puts "10. Font rendering test"
send_notification normal "Font Rendering" "Testing Ancient Medium font\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789" "preferences-desktop-font"

puts "\nDemo complete! Check your notification area."
puts "Critical notification will remain until dismissed."
