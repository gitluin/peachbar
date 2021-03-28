#!/bin/sh

if test -f "$HOME/.config/peachbar/peachbar.conf"; then
	. "$HOME/.config/peachbar/peachbar.conf"
else
	echo "Missing config file: $HOME/.config/peachbar/peachbar.conf"
	exit -1
fi

# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"

peachbar-sys.sh &

# Set the number of clickable areas based on the number of tags, monitors,
#	number of modules, and the layout symbol.
NUMTAGS="$(echo -e $(echo $TAGS | sed 's/:/\\n/g') | wc -l)"

# Every module defaults to getting 2 clickables
test -z "$NUMCLICKPERMOD" && NUMCLICKPERMOD=2
NUMMOD="$(echo -e $(echo $MODULES | sed 's/ /\\n/g') | wc -l)"

NUMMON="$(xrandr -q | grep ' connected' | wc -l)"

NUMFIELDS="$(($NUMTAGS + $(($NUMMOD * $NUMCLICKPERMOD)) + 1))"
NUMCLICK="$(($NUMFIELDS * $NUMMON))"

peachbar-sara.sh < "$INFF" | lemonbar \
	-a $NUMCLICK \
	-g x"$BARH"+"$BARX"+"$BARY" \
	-d \
	-f "$BARFONT" -f "$ICONFONT" \
	-B "$BARBG" -F "$BARFG" \
	| sh &

# Pull information from sara
exec sara > "$INFF"
