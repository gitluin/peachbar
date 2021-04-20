#!/bin/sh

BTSTATUS="on\noff"

echo -e "On\nOff" | bluetoothctl power $(eval $(echo -e "echo -e \"\$BTSTATUS\" | grep -i $(rofi -dmenu -p "Power" -no-custom -monitor -3 -width 5 -lines 2 -theme-str 'entry { placeholder: ""; } inputbar { children: [prompt, textbox-prompt-colon];}' -font "Noto Sans 10" -hide-scrollbar -color-window "#282a36, #282a36, #f8f8f2" -color-normal "#282a36, #f8f8f2, #282a36, #005577, #f8f8f2" -color-active "#282a36, #f8f8f2, #282a36, #007763, #f8f8f2" -color-urgent "#282a36, #f8f8f2, #282a36, #77003d, #f8f8f2")"))
