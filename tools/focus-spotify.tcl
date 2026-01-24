#!/usr/bin/env tclsh

# Focus Spotify on workspace 10, or launch it there if not running.

set id [exec bash -lc {
  swaymsg -t get_tree | jq -r '
    .. | objects
    | select(.app_id=="spotify" or .app_id=="com.spotify.Client" or ((.name? // "") | test("Spotify")))
    | .id
  ' | head -n1
}]
set id [string trim $id]

if {$id eq ""} {
  catch {exec swaymsg "workspace number 10" 2>/dev/null}
  exec bash -lc {
    if command -v gtk-launch >/dev/null 2>&1; then
      gtk-launch com.spotify.Client
    elif command -v flatpak >/dev/null 2>&1; then
      flatpak run com.spotify.Client
    else
      spotify
    fi
  } &
} else {
  catch {exec swaymsg "[con_id=$id] move container to workspace number 10" 2>/dev/null}
  catch {exec swaymsg "workspace number 10" 2>/dev/null}
  catch {exec swaymsg "[con_id=$id] focus" 2>/dev/null}
}
