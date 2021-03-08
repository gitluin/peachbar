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

peachbar-sara.sh < "$INFF" | lemonbar -a 32 -g x"$BARH"+"$BARX"+"$BARY" -d -f "$BARFONT" -f "$ICONFONT" -B "$BARBG" -F "$BARFG" | sh &

# Pull information from sara
exec sara > "$INFF"
