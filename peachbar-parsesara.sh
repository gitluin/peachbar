#!/bin/bash

# TODO: config file
# Colors
FREECOLFG="#ffffff"
FREECOLBG="#85000000"
OCCCOLFG="#ffffff"
OCCCOLBG="#504e4e"
SELCOLFG="#ffffff"
SELCOLBG="#4863a0"

# TODO: POSIX

# TODO: Not jank
NUMDESK=8
# Pass MONLINE, TAGS, LEFTSYM, RIGHTSYM
# Get back sara v1.0-style output:
# <1>  2   3  []=
MONLINE="$1"
TAGS="$2"

TAGSTR=""

# MonNum:OccupiedDesks:SelectedDesks:LayoutSymbol
# 0:00000000:00000000:[]= -> 00000000:00000000:[]=
MONLINE="$(cut -d':' -f2-4 <<<"$MONLINE")"
ISDESKOCC="$(cut -d':' -f1 <<<"$MONLINE")"
ISDESKSEL="$(cut -d':' -f2 <<<"$MONLINE")"
LAYOUTSYM="$(cut -d':' -f3 <<<"$MONLINE")"

# TODO: boxes!
#for (( i=0; i<${#ISDESKOCC}; i++ )); do
for (( i=0; i<$NUMDESK; i++ )); do
	if [ ${ISDESKSEL:$i:1} -eq 1 ]; then
		TAGSTR="${TAGSTR}%{F$SELCOLFG}%{B$SELCOLBG}%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}   ${TAGS:$i:1}   %{A}%{A}%{B-}%{F-}"
	elif [ ${ISDESKOCC:$i:1} -eq 1 ]; then
		TAGSTR="${TAGSTR}%{F$OCCCOLFG}%{B$OCCCOLBG}%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}   ${TAGS:$i:1}   %{A}%{A}%{B-}%{F-}"
	else
		TAGSTR="${TAGSTR}%{F$FREECOLFG}%{B$FREECOLBG}%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}   ${TAGS:$i:1}   %{A}%{A}%{B-}%{F-}"
	fi
done
TAGSTR="${TAGSTR}%{F$FREECOLFG}%{B$FREECOLBG}%{A:sarasock 'setlayout tile':}%{A3:sarasock 'setlayout monocle':}  $LAYOUTSYM  %{A}%{A}%{B-}%{F-}"

echo "${TAGSTR}"
