#!/bin/bash

name_file="/home/ishmael/.sbar/.name"

# -------------------------------
# Set brightness, get ready to update

# Extra one is for 100%
brightsyms=( o D O O )

# Pass A/U to do the thing
	# up/down
light "$1" "$2"

# Get brightness
bright=$(light -G)
bright=${bright%.*}
i=$(( $bright/33 ))
brightsym="${brightsyms[$i]}"

/ibin/sbar_update.sh "$(sed "s/\S\+/$brightsym/4" "$name_file")"
/ibin/sbar_update.sh "$(sed "s/\S\+/$bright%/5" "$name_file")"
