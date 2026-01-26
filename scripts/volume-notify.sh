#!/bin/bash
# Volume notification script with progress bar for fnott

# Process command line argument
case "$1" in
    up)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|mute}"
        exit 1
        ;;
esac

# Get current volume and mute status
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP '(yes|no)')

# Store notification ID in a temp file to enable replacement
NOTIF_ID_FILE="/tmp/volume-notify-id"
if [ -f "$NOTIF_ID_FILE" ] && [ -s "$NOTIF_ID_FILE" ]; then
    REPLACE_ID=$(cat "$NOTIF_ID_FILE" 2>/dev/null || echo "0")
else
    REPLACE_ID="0"
fi

# Send notification with progress bar using gdbus for proper replacement
# gdbus Notify signature: (susssasa{sv}i) = app_name, replaces_id, app_icon, summary, body, actions, hints, expire_timeout
if [ "$muted" = "yes" ]; then
    NOTIF_ID=$(gdbus call --session \
        --dest=org.freedesktop.Notifications \
        --object-path=/org/freedesktop/Notifications \
        --method=org.freedesktop.Notifications.Notify \
        "volume-notify" "$REPLACE_ID" "" "Volume" "Muted" \
        "[]" "@a{sv} {'value': <int32 0>}" 2000 | grep -oP '\(uint32 \K\d+')
else
    NOTIF_ID=$(gdbus call --session \
        --dest=org.freedesktop.Notifications \
        --object-path=/org/freedesktop/Notifications \
        --method=org.freedesktop.Notifications.Notify \
        "volume-notify" "$REPLACE_ID" "" "Volume" "${volume}%" \
        "[]" "@a{sv} {'value': <int32 ${volume}>}" 2000 | grep -oP '\(uint32 \K\d+')
fi

# Save the notification ID for next replacement
echo "$NOTIF_ID" > "$NOTIF_ID_FILE"
