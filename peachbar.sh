#!/bin/sh

if test -f "$HOME/.config/peachbar/peachbar.conf"; then
	. "$HOME/.config/peachbar/peachbar.conf"
else
	echo "Missing config file: $HOME/.config/peachbar/peachbar.conf"
	exit -1
fi

# Clear out any stale fifos
CleanFifos() {
	PEACHFIFOS="$(ls "/tmp/" | grep "peachbar")"
	if ! test -z "$PEACHFIFOS"; then
		for TO_DEL in $PEACHFIFOS; do
			test -e "/tmp/$TO_DEL" && sudo rm "/tmp/$TO_DEL"
		done
	fi
}

CleanFifos

test -e "$PEACHFIFO" && sudo rm "$PEACHFIFO"
sudo mkfifo -m 777 "$PEACHFIFO"

#sara-interceptor.sh "$SARAFIFO" $PEACHFIFO &

# Set the number of clickable areas based on the number of tags, monitors,
#	number of modules, and the layout symbol.
# Every non-sara module defaults to getting 2 clickables
#NUMTAGS="$(echo -e $(echo $TAGS | sed 's/:/\\n/g') | wc -l)"
#test -z "$NUMCLICKPERMOD" && NUMCLICKPERMOD=2
#NUMMOD="$(echo -e $(echo $MODULES | sed 's/ /\\n/g') | wc -l)"
#NUMMON="$(xrandr -q | grep ' connected' | wc -l)"
#NUMFIELDS="$(($NUMTAGS + $(($NUMMOD * $NUMCLICKPERMOD)) + 1))"
#NUMCLICK="$(($NUMFIELDS * $NUMMON))"

./peachbar-sys.sh < "$PEACHFIFO" | lemonbar \
	-a 40 \
	-g "$BARW"x"$BARH"+"$BARX"+"$BARY" \
	-d \
	-f "$BARFONT" \
	-f "$ICONFONT" \
	-B "$BARBG" \
	-F "$BARFG" \
	| sh &
