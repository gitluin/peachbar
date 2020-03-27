#!/bin/bash

# Pass MONLINE, TAGS, LEFTSYM, RIGHTSYM
# Get back sara v1.0-style output:
# <1>  2   3  []=
MONLINE="$1"
TAGS="$2"
LEFTSYM="$3"
RIGHTSYM="$4"

TAGSTR=""

# MonNum:OccupiedDesks:SelectedDesks:LayoutSymbol
# 0:00000000:00000000:[]= -> 00000000:00000000:[]=
MONLINE="$(cut -d':' -f2-4 <<<"$MONLINE")"
ISDESKOCC="$(cut -d':' -f1 <<<"$MONLINE")"
ISDESKSEL="$(cut -d':' -f2 <<<"$MONLINE")"
LAYOUTSYM="$(cut -d':' -f3 <<<"$MONLINE")"

for (( i=0; i<${#ISDESKOCC}; i++ )); do
	if [ ${ISDESKSEL:$i:1} -eq 1 ]; then
		TAGSTR="${TAGSTR} $LEFTSYM${TAGS:$i:1}$RIGHTSYM "
	elif [ ${ISDESKOCC:$i:1} -eq 1 ]; then
		TAGSTR="${TAGSTR}   ${TAGS:$i:1}   "
	fi
done
TAGSTR="${TAGSTR}  $LAYOUTSYM"

echo "$TAGSTR"
