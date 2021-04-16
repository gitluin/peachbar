#!/bin/bash

# TODO: are there cases where you would have to also write to
#	$PEACHFIFO after interrupting sleep?
# TODO: if peachbar-signal.sh blocks while reading from fifo,
#	it should exit.
# TODO: if peachbar calls a module that is blocked, it should
#	skip it
# TODO: note to user about explain graphical options
# TODO: note to user that wal gets overridden
# TODO: note to user that additional monitors beyond what you specified
#	are assigned the layout for S0


# If not specified, default to N
# Accepts raw ASYNC, MODULES
CleanAsync() {
	LOCAL_ASYNC="$1"
	# Remove lemonbar stuff, don't quote later so extra whitespace appears as one
	LOCAL_MODULES="$(echo "$2" | sed 's/%{[^}]\+}/ /g')"

	for LMODULE in $LOCAL_MODULES; do
		test -z "$(echo "$LOCAL_ASYNC" | grep -o "$LMODULE")" && \
			LOCAL_ASYNC="${LOCAL_ASYNC} $LMODULE:N"
	done

	echo "$LOCAL_ASYNC"
}


CleanFifos() {
	PEACHFIFOS="$(ls "/tmp/" | grep "peachbar-Module")"
	if ! test -z "$PEACHFIFOS"; then
		for TO_DEL in $PEACHFIFOS; do
			test -e "/tmp/$TO_DEL" && sudo rm "/tmp/$TO_DEL"
		done
	fi
}


Cleanup() {
	CleanFifos
	kill 0
}


Configure() {
	if test -f "$HOME/.config/peachbar/peachbar.conf"; then
		. "$HOME/.config/peachbar/peachbar.conf"

		# ------------------------------------------
		# wal integration
		if test "$USEWAL" = "TRUE" && test -f "$HOME/.cache/wal/colors.sh"; then
			. "$HOME/.cache/wal/colors.sh"

			BARFG="$foreground"
			BARBG="$background"

			. "$HOME/.config/peachbar/peachbar.conf"
		fi

		test -z "$DEFINTERVAL" && DEFINTERVAL=10

	else
		echo "Missing config file: $HOME/.config/peachbar/peachbar.conf"
		exit -1
	fi

	if test -f "$HOME/.config/peachbar/peachbar-modules.conf"; then
		. "$HOME/.config/peachbar/peachbar-modules.conf"
	else
		echo "Missing modules.conf file: $HOME/.config/peachbar/peachbar-modules.conf"
		exit -1
	fi
}

# TODO: lemonbar-equivalent monitor detection
#	lemonbar offloads to randr when detected, XINERAMA otherwise
#	xrandr --list-monitors?
CountMon() {
	echo "$(( $(xrandr --listactivemonitors | wc -l) - 1))"
}


EvalModule() {
	MODULENAME=$1
	MONNUM=$2
	MODULEASYNC=$3
	echo "$($MODULENAME $MONNUM)"

	# If module is not self-managed, use a default timer
	if test "$MODULEASYNC" = "N"; then
		MODULEFIFO="peachbar-Module$MODULENAME.peachid"
		>&2 echo meow2
		# TODO: replace detach with just the timer - execvp?
		detach -- peachbar-timer $MODULENAME $DEFINTERVAL $MODULEFIFO $PEACHFIFO
		>&2 echo meow3
	fi

	>&2 echo hungus
}


# Any modules not detected fail here without crashing (but they will output),
#	potentially to STDOUT or STDERR
EvalModuleContents() {
	# Must be eval'd as one line, else it will start ripping things out
	#	linewise to try and eval them as a job
	#	(as if you'd typed $(%{S0}), etc.)
	LOCAL_MODULE_CONTENTS="$(echo $1 | sed 's/} {/}{/g' | sed 's/} %/}%/g')"
	TO_OUT="$(eval echo $LOCAL_MODULE_CONTENTS)"

	# Replace any %{FA}%{BA} formatters output by modules with the color
	#	formatters inserted in InsertEvalArgs after each alignment
	#	formatter.
	# NOTE: this will produce junk if COLORS insertion doesn't work
	# Remove whitespace, insert newlines, delete empty lines
	# Grab the line after the %{.} align line, overwrite %{FA}
	# Grab the next two lines after the %{.} align line, overwrite %{BA}
	#	with the last line in hold (i.e. line 2)
	# Add explicit $ delims to line ends to remove non-module-internal
	#	whitespace
	TO_OUT="$(echo $TO_OUT | \
		sed 's/} {/}{/g' | \
		sed 's/} %/}%/g' | \
		sed 's/\(%{[^}]\+}\)/\n\1\n/g' | \
		sed -n '/^$/d; p' | \
		sed -n '/%{.}/,+1h; /%{FA}/g; p' | \
		sed -n '/%{.}/,+2h; /%{BA}/g; p' | \
		sed 's/$/{{PEACHBAR}}/g')"
	TO_OUT="$(echo $TO_OUT | \
		sed 's/{{PEACHBAR}} //g' | \
		sed 's/{{PEACHBAR}}$//g')"

	echo "$TO_OUT"
}


# Accepts raw $MODULES variable
InitFiles() {
	# Remove lemonbar stuff, don't quote later so extra whitespace appears as one
	INT_MODULES="$(echo "$1" | sed 's/%{[^}]\+}/ /g')"

	for TO_INIT in $INT_MODULES; do
		MODFILE="/tmp/peachbar-Module${TO_INIT}.peachid"
		! test -e "$MODFILE" && touch "$MODFILE"
	done
}


# InitStatus
#	1. detect number of screens
#	2. if num_screen > count of %{S#} specified, copy until ==
#	3. surround Name with {{Module____}}
#	4. wrap Name in $()
#	5. eval the string to generate output
InitStatus() {
	LOCAL_MODULES="$1"
	MULTI="$(CountMon)"
	NUM_SPECD="$(echo $MODULES | grep -o "S[0-9]" | wc -l)"

	# If %{S0} not provided, add it
	if test -z "$(echo $MODULES | grep -o "S0")"; then
		MODULES="%{S0}$MODULES"
		NUM_SPECD=1
		LOCAL_MODULES="$MODULES"
	fi

	# If missing modules for other monitors, copy %{S0} to them
	LOCAL_MODULES_BAK="$LOCAL_MODULES"
	while test $NUM_SPECD -lt $MULTI; do
		NEW_TEXT="$(echo $LOCAL_MODULES_BAK | sed "s/%{S0}/%S{$NUM_SPECD}/")"
		LOCAL_MODULES="$LOCAL_MODULES${NEW_TEXT}"
		NUM_SPECD="$(( $NUM_SPECD + 1 ))"
	done

	# After each alignment, paste the associated color specifications
	# Before each alignment, paste the color "resetter" (ALIGN_COLOR_END)
	ALIGN_COLOR_END="%{F$BARFG}%{B$BARBG}"

	# Properly surround alignment sections with color toggles
	LOCAL_COLORS="$(echo $COLORS | sed 's/\(%{[lcr]}\)/\n\1/g' | sed '/^$/d')"
	ALIGNS="l c r"
	for ALIGN in $ALIGNS; do
		TO_INS="$(echo "$LOCAL_COLORS" | sed -n "/%{$ALIGN}/ s/%{.}//p")"
		LOCAL_MODULES="$(echo $LOCAL_MODULES | sed "s/%{$ALIGN}/%{$ALIGN}$TO_INS/g")"
	done

	LOCAL_MODULES="$(echo $LOCAL_MODULES | \
		sed "s/\(%{.}\)/$ALIGN_COLOR_END\1/g" | \
		sed "s/\(%{S[0-9]}\)$ALIGN_COLOR_END/\1/g" | \
		sed "s/\(%{S[1-9]}\)/$ALIGN_COLOR_END\1/g" | \
		sed "s/$/$ALIGN_COLOR_END/")"

	# Convert to individual lines, then convert "Name" to
	#	"{{ModuleName}}$(Name){{ModuleName-}}"
	MODULE_CONTENTS="$(echo $LOCAL_MODULES | \
		sed 's/\(%{[^}]\+}\)/\n\1\n/g' | \
		sed 's/ /\n/g' | \
		sed '/^$/d' | \
		sed '/%{.*}/! s/\(.*\)/{{Module\1}}$(\1){{Module\1-}}/g')"

	MODULE_CONTENTS="$(InsertEvalArgs "$MODULE_CONTENTS")"

	EVALD_CONTENTS="$(EvalModuleContents "$MODULE_CONTENTS")"

	echo "$EVALD_CONTENTS"
}


InsertEvalArgs() {
	LOCAL_MODULE_CONTENTS="$1"
	MOD_TO_CHANGE="$2"
	# All modules
	test -z "$MOD_TO_CHANGE" && MOD_TO_CHANGE="^{{"

	# Store %{S.} tags in hold space, append to lines with a module call
	# Remove explicit $ characters
	# Move the . from %{S.} inside the module call
	LOCAL_MODULE_CONTENTS="$(echo "$LOCAL_MODULE_CONTENTS" | \
		sed -n '/%{S.}/h; /\$(.*)/G; l' | \
		sed 's/\$$//g' | \
		sed "/$MOD_TO_CHANGE/ s/\$(\(.*\))\(.*\)\\\n%{S\(.\)}/\$(EvalModule \1 \3)\2/g")"

	if test "$MOD_TO_CHANGE" = "^{{"; then
		# Works on raw, user-defined ASYNC
		# Insert async status after monnum
		for ASTATUS in $ASYNC; do
			ASREG="$(echo $ASTATUS | cut -d':' -f1)"
			ASTAT="$(echo $ASTATUS | cut -d':' -f2)"
			LOCAL_MODULE_CONTENTS="$(echo "$LOCAL_MODULE_CONTENTS" | \
				sed "s/\$(\(.*$ASREG.*\))/\$(\1 $ASTAT)/g")"
		done
	else
		ASTAT="$(echo $ASYNC | \
			sed "s/.*\($MOD_TO_CHANGE:.\).*/\1/g" | \
			cut -d':' -f2)"
		LOCAL_MODULE_CONTENTS="$(echo "$LOCAL_MODULE_CONTENTS" | \
			sed "s/\$(\(.*$MOD_TO_CHANGE.*\))/\$(\1 $ASTAT)/g")"
	fi

	echo "$LOCAL_MODULE_CONTENTS"
}


# sleep, get sleep pid, echo sleep pid, echo Module name when sleep done
# https://unix.stackexchange.com/questions/427115/listen-for-exit-of-process-given-pid
# wait doesn't work because you can't wait on someone else's child process
ModuleTimer() {
      MODULENAME=$1
      INTERVAL=$2
      MODULEFIFO="peachbar-Module$MODULENAME.peachid"

      sleep $INTERVAL &
      MYPID=$!
      echo $MYPID > $MODULEFIFO
      >&2 echo fleepo
      tail --pid=$MYPID -f /dev/null && echo $MODULENAME > $PEACHFIFO &
      >&2 echo meepo
}


# Prints MODULE_CONTENTS to lemonbar, adding in module delimeters
PrintStatus() {
	LOCAL_MODULE_CONTENTS="$1"
	LOCAL_MODDELIMF="$2"
	LOCAL_MODDELIMB="$3"

	# Remove newlines
	# Replace {{ModuleName}} and {{ModuleName-}} tags with $MODDELIMS
	# [^-}}] and [^}}] prevent greedy matching
	STATUSLINE="$(echo $LOCAL_MODULE_CONTENTS | \
		sed "s/{{[^-}}]*}}/$LOCAL_MODDELIMF/g" | \
		sed "s/{{[^}}]*}}/$LOCAL_MODDELIMB/g")"

	echo -e "$STATUSLINE\n"
}


ReConfigure() {
	Configure
	MODULE_CONTENTS="$(InitStatus "$MODULES")"
	PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"
}


# Only operates on single monlines
UpdateModuleText() {
	LOCAL_MODULE_CONTENTS="$1"
	MODULE="$2"

	# Replace text with eval call
	LOCAL_MODULE_CONTENTS="$(echo $LOCAL_MODULE_CONTENTS | \
		sed "s/\({{Module$MODULE}}\).*\({{Module$MODULE-}}\)/\1\$($MODULE)\2/")"

	LOCAL_MODULE_CONTENTS="$(InsertEvalArgs "$LOCAL_MODULE_CONTENTS" "$MODULE")"

	EVALD_CONTENTS="$(EvalModuleContents "$MODULE_CONTENTS")"

	echo "$EVALD_CONTENTS"
}


# ------------------------------------------
# Initialization
# ------------------------------------------
# Kill zombie peachbar-sys.sh instances
PEACHPIDS="$(pgrep "peachbar-sys")"
for PEACHPID in $PEACHPIDS; do
	! test $PEACHPID = $$ && kill -9 $PEACHPID
done

CleanFifos

Configure
ASYNC="$(CleanAsync "$ASYNC" "$MODULES")"
InitFiles "$MODULES"


# ------------------------------------------
# Main Loop
# ------------------------------------------
# Reload config files on signal, reinit to update colors, etc.
trap "ReConfigure" SIGUSR1
# from gitlab.com/mellok1488/dotfiles/panel, should kill all sleeps, etc.
# TODO: bad
#trap 'trap - TERM; Cleanup' TERM QUIT EXIT

>&2 echo here1
#MODULE_CONTENTS="$(InitStatus "$MODULES")"
InitStatus "$MODULES"
#>&2 echo here2
#PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"
#>&2 echo here3

## TODO: closes if nothing to be read?
#while read line; do
#	# $line is a module name
#	if test "$line" != "All"; then
#		# Replace module text with new calls, then eval
#		MODULE_CONTENTS="$(UpdateModuleText "$MODULE_CONTENTS" "$line")"
#	else
#		MODULE_CONTENTS="$(InitStatus "$MODULES")"
#	fi
#
#	PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"
#done
