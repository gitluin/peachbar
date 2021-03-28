#!/bin/bash

if test -f "$HOME/.config/peachbar/peachbar.conf"; then
	. "$HOME/.config/peachbar/peachbar.conf"
else
	echo "Missing config file: $HOME/.config/peachbar/peachbar.conf"
	exit -1
fi

TO_OUT=""


# ------------------------------------------
# Parse sara output
# ------------------------------------------
# TODO: TAGS spacing does not look okay with arbitrary tags! Need to standardize.
#	1. Determine which tag has the most characters
#	2. Give that one 2 spaces of padding
#	3. Add the difference to everyone else
#		a. What about odd numbers?
ParseSara() {
	LTBUTTONSTART="%{A:sarasock 'setlayout tile':}%{A3:sarasock 'setlayout monocle':}"
	LTBUTTONEND="%{A}%{A}"

	# Pass MONLINE, TAGS, SELTAGS, OCCTAGS
	MONLINE="$1"
	TAGS="$2"
	SELTAGS="$3"
	OCCTAGS="$4"

	# In case user wants to be less specific with symbols
	test -z "$SELTAGS" && SELTAGS="$TAGS"
	test -z "$OCCTAGS" && OCCTAGS="$TAGS"
	test -z "$TAGDELIMF" && TAGDELIMF="   "
	test -z "$TAGDELIMB" && TAGDELIMB="$TAGDELIMF"
	test -z "$LTDELIMF" && LTDELIMF="  "
	test -z "$LTDELIMB" && LTDELIMB="$LTDELIMF"

	TAGSTR="%{B$INFOBG}"

	# MonNum:OccupiedDesks:SelectedDesks:LayoutSymbol
	# 0:000000000:000000000:[]= -> 000000000:000000000:[]=
	MONLINE="$(echo $MONLINE | cut -d':' -f2-4)"
	ISDESKOCC="$(echo $MONLINE | cut -d':' -f1)"
	ISDESKSEL="$(echo $MONLINE | cut -d':' -f2)"
	LAYOUTSYM="$(echo $MONLINE | cut -d':' -f3)"

	# TODO: is ${#STRING} portable?
	# TODO: options for all tags or just occupied
	for (( i=0; i<${#ISDESKOCC}; i++ )); do
		# TODO: does not play nice with nested clickables. Causes tags to disappear on extra monitor.
		#	Possibly because the limit for clickables was previously reached?
		#TAGBUTTONSTART="%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}"
		#TAGBUTTONEND="%{A}%{A}"

		TAGBUTTONSTART="%{A:sarasock 'view $i':}"
		TAGBUTTONEND="%{A}"

		if test "$(echo $ISDESKSEL | cut -c$((i + 1)))" -eq 1; then
			TMPFG=$SELCOLFG
			TMPBG=$SELCOLBG
			TMPTAGS=$SELTAGS
		elif test "$(echo $ISDESKOCC | cut -c$((i + 1)))" -eq 1; then
			TMPFG=$OCCCOLFG
			TMPBG=$OCCCOLBG
			TMPTAGS=$OCCTAGS
		else
			TMPFG=$INFOFG
			TMPBG=$INFOBG
			TMPTAGS=$TAGS
		fi

		#TAGSTR="${TAGSTR}%{F$TMPFG}%{B$TMPBG}${TAGBUTTONSTART}   $(echo -e $TMPTAGS | cut -d':' -f$((i + 1)) )   ${TAGBUTTONEND}%{B$INFOBG}%{F$INFOFG}"
		TAGSTR="${TAGSTR}%{F$TMPFG}%{B$TMPBG}${TAGBUTTONSTART}${TAGDELIMF}$(echo -e $TMPTAGS | cut -d':' -f$((i + 1)) )${TAGDELIMB}${TAGBUTTONEND}%{B$INFOBG}%{F$INFOFG}"
	done
	TAGSTR="${TAGSTR}${LTBUTTONSTART}${LTDELIMF}$LAYOUTSYM${LTDELIMB}${LTBUTTONEND}%{B$BARBG}%{F$BARFG}"

	echo -e "${TAGSTR}"
}


# ------------------------------------------
# Grab information and print it out
# ------------------------------------------
GrabNPrint() {
	MONLINE=$1
	MULTI=$(xrandr -q | grep "$EXTDIS" | cut -d' ' -f2)

	if [[ "${MONLINE:0:1}" =~ ^[0-4].* ]]; then
		# monitor 0 (lemonbar says it's 1)
		MONLINE0="$(cut -d' ' -f1 <<<"$MONLINE")"
		TAGSTR0="$(ParseSara $MONLINE0 $TAGS $SELTAGS $OCCTAGS)"

		if test "$MULTI" = "connected"; then
			#MONLINE1="$(cut -d'|' -f2 <<<"$MONLINE")"

			# monitor 1 (lemonbar says it's 0)
			MONLINE1="$(cut -d' ' -f2 <<<"$MONLINE")"
			TAGSTR1="$(ParseSara $MONLINE1 $TAGS $SELTAGS $OCCTAGS)"
		fi

	else
		BARSTATS="$MONLINE"
	fi

	if test "$MULTI" = "connected"; then
		TO_OUT="%{B$BARBG}%{S0}%{l}${TAGSTR1}%{r}$BARSTATS%{S1}%{l}${TAGSTR0}%{r}$BARSTATS%{B-}"
	else
		TO_OUT="%{B$BARBG}%{l}${TAGSTR0}%{r}$BARSTATS%{B-}"
	fi

	printf "%s\n" "$TO_OUT"
}

# ------------------------------------------
# Initialization
# ------------------------------------------
# Kill other peachbar-sara.sh instances
# For some reason, pgrep and 'peachbar-*.sh'
#	don't play nice - something about the
#	[.].
PEACHPIDS="$(pgrep "peachbar-sara")"
for PEACHPID in $PEACHPIDS; do
	! test $PEACHPID = $$ && kill -9 $PEACHPID
done


# ------------------------------------------
# Main loop
# ------------------------------------------
# Reload config file on signal
# TODO: doesn't quite work
#	Because I'm not piping anything into GrabNPrint - it needs $line
#	Should I store the string and then reprint to lemonbar upon SIGUSR2?
#		This would require re-evaling all the variables after change
trap ". $HOME/.config/peachbar/peachbar.conf; printf '%s\n' \"$TO_OUT\"" SIGUSR2
# from gitlab.com/mellok1488/dotfiles/panel
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT
while read line; do
	GrabNPrint "$line"
done
