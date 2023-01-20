#!/bin/sh
# toggle status of Auto-Mute
if amixer -c 0 sget 'Auto-Mute Mode' | grep --quiet -F "Item0: 'Enabled"
then
    amixer -c 0 sset 'Auto-Mute Mode' Disabled
else
    amixer -c 0 sset 'Auto-Mute Mode' Enabled
fi
