#!/bin/bash

# Async:
# peachbar-sys.sh reads from a fifo that tells it what needs updating.
# 	basically, a queue of to-dos.
#	sara-interceptor.sh $SARAFIFO $PEACHFIFO &
# 	peachbar-sys.sh < $PEACHFIFO | lemonbar | sh &
# 	exec sara > $SARAFIFO
# 	i. each module has a sleep that forks off and then writes the module name to
# 		$PEACHFIFO when done.
# 		peachbar-sys.sh while read line; do's things.
# 		if receive "All", then updates entire bar
# 		if nothing in $PEACHFIFO, no work is done!
# 	ii. peachbar-signal.sh should now push updates to $PEACHFIFO, not signal the process
# 		Each module gets its own fifo, i.e. "peachbar-ModuleAudio.fifo"
# 			each module writes its sleep pid to its fifo when on a timer
#			TODO: are there cases where you would have to also write to $PEACHFIFO?
# 			peachbar-signal.sh reads sleep pid from peachbar-ModuleName.fifo, and
# 				kills it. killing it will trigger the subsequent echo. the bar update
# 				will automatically set a new timer.
#				TODO: if peachbar-signal.sh blocks while reading from fifo, it should exit
#
#
# Modules are specified by the user with lemonbar syntax in a string:
#	"%{S0}%{l}Audio Network%{c}Sara%{r}Battery%{S1}%{l}Audio Network%{c}Sara Layout%{r}"
#
# Module text is saved by peachbar in this format as MODULE_CONTENTS:
#	%{S0}
#	%{l}
#	{{ModuleAudio}}xxx{{ModuleAudio-}}
#	%{r}
#	{{ModuleNetwork}}yyy{{ModuleNetwork-}}
#	%{S1}
#	%{l}
#	{{ModuleBattery}}zzz{{ModuleBattery-}}
#	%{r}
#	{{ModuleBright}}uuu{{ModuleBright-}}
#
# End goal is to output a fully lemonbar-prepped STATUSLINE
#
#
# All modules get told what monitor they are on.
# {{.*}} and newlines are not permitted inside your bar text, i.e. as module
#	output, or as a module name. You'll screw up bar text parsing.
#	Anything lemonbar is okay, though.
# TODO: dependency checks in install.sh
# Current dependencies:
#	lemonbar-xft
#	GNU coreutils (mostly for GNU sed at the moment)
#	bash (for loops)
# TODO: note to user about explain graphical options
# TODO: note to user that wal gets overridden
# TODO: note to user that additional monitors beyond what you specified
#	are assigned the layout for S0
# TODO: what if peachbar calls a module that is blocked?

# Async status is "Y" if the module likes to update only when it has new
#	information (like reading from a fifo), and "N" if it should be
#	run on a timer (DEFINTERVAL). This should have no impact on
#	performance, just on currentness of information if it *is* async.
# ASYNC="Sara:Y Audio:Y Network:N"

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


# TODO:
# ParseSara Module:
#	Must read from the INFF on its own
#		sara-interceptor.sh split the single outputstats() line into N fifos, one
#			for each monitor? Then, when ParseSara gets called, it just reads
#			from the associated fifo!
#		sara-interceptor.sh while read line; do's $SARAFIFO, and then spits it back
#			into $SARAFIFO and writes to $PEACHFIFO


# TODO: lemonbar-equivalent monitor detection
#	lemonbar offloads to randr when detected, XINERAMA otherwise
#	xrandr --list-monitors?
CountMon() {
	echo "$(( $(xrandr --listactivemonitors | wc -l) - 1))"
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

	# If %{S0} not provided and it is needed, override MODULES
	if test $NUM_SPECD -eq 0 && test $MULTI -gt 1; then
		MODULES="%{S0}$MODULES"
		NUM_SPECD=1
		LOCAL_MODULES="$MODULES"
	fi

	# If missing modules for other monitors, copy %{S0} to them
	LOCAL_MODULES_BAK="$LOCAL_MODULES"
	while test $NUM_SPEC -lt $MULTI; do
		NEW_TEXT="$(echo $LOCAL_MODULES_BAK | sed "s/%{S0}/%S{$NUM_SPECD}/")"
		LOCAL_MODULES="$LOCAL_MODULES${NEW_TEXT}"
		NUM_SPECD="$(( $NUM_SPECD + 1 ))"
	done

	# Convert to individual lines, then convert "Name" to
	#	"{{ModuleName}}$(Name){{ModuleName-}}"
	MODULE_CONTENTS="$(echo $LOCAL_MODULES | \
		sed 's/\(%{[^}]\+}\)/\n\1\n/g' | \
		sed 's/ /\n/g' | \
		sed '/^$/d' | \
		sed '/%{.*}/! s/\(.*\)/{{Module\1}}$(\1){{Module\1-}}/g')"

	MODULE_CONTENTS="$(InsertMonNums "$MODULE_CONTENTS")"

	EVALD_CONTENTS="$(EvalModuleContents "$MODULE_CONTENTS")"

	echo "$EVALD_CONTENTS"
}


InsertMonNums() {
	LOCAL_MODULE_CONTENTS="$1"
	MOD_TO_CHANGE="$2"
	LOCAL_ASYNC="$3"
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
				sed "s/\$(\($ASREG.*\))/\$(\1 $ASTAT)/g")"
		done
	else
		ASTAT="$(echo $ASYNC | \
			sed "s/.*\($MOD_TO_CHANGE:.\).*/\1/g" | \
			cut -d':' -f2)"
		LOCAL_MODULE_CONTENTS="$(echo "$LOCAL_MODULE_CONTENTS" | \
			sed "s/\$(\($MOD_TO_CHANGE.*\))/\$(\1 $ASTAT)/g")"
	fi

	echo "$LOCAL_MODULE_CONTENTS"
}


# Any modules not detected fail here without crashing (but they will output),
#	potentially to STDOUT or STDERR
EvalModuleContents() {
	# Must be eval'd as one line, else it will start ripping things out
	#	linewise to try and eval them as a job
	#	(as if you'd typed $(%{S0}), etc.)
	LOCAL_MODULE_CONTENTS="$($1 | sed 's/ //g')"
	TO_OUT="$(eval echo $LOCAL_MODULE_CONTENTS)"

	echo "$TO_OUT"
}


# Accepts raw $MODULES variable
InitFifos() {
	# Remove lemonbar stuff, don't quote later so extra whitespace appears as one
	INT_MODULES="$(echo "$1" | sed 's/%{[^}]\+}/ /g')"

	for TO_INIT in $INT_MODULES; do
		MODFIFO="/tmp/peachbar-Module${TO_INIT}.fifo"
		! test -e "$MODFIFO" && sudo mkfifo -m 777 "$MODFIFO"
	done
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
			INFOBG="$color1"
			OCCCOLBG="$color2"
			SELCOLBG="$color15"

			. "$HOME/.config/peachbar/peachbar.conf"
		fi
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


# If module is not self-managed, use a default timer
EvalModule() {
	MODULENAME=$1
	MONNUM=$2
	MODULEASYNC=$3
	echo "$($MODULENAME $MONNUM)"
	(test "$MODULEASYNC" != "y" || test "$MODULEASYNC" != "Y") && \
		ModuleTimer $MODULENAME $DEFINTERVAL
}


# sleep, get sleep pid, echo sleep pid, echo Module name when sleep done
# https://unix.stackexchange.com/questions/427115/listen-for-exit-of-process-given-pid
# wait doesn't work because you can't wait on someone else's child process
ModuleTimer() {
      MODULENAME=$1
      INTERVAL=$2
      MODULEFIFO="peachbar-Module$MODULENAME.fifo"

      sleep $INTERVAL &
      MYPID=$!
      echo $MYPID > $MODULEFIFO
      tail --pid=$MYPID -f /dev/null && echo $MODULENAME > $PEACHFIFO &
}


CleanFifos() {
	PEACHFIFOS="$(ls "/tmp/" | grep "peachbar")"
	for TO_DEL in "$PEACHFIFOS"; do
		sudo rm "$TO_DEL"
	done
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
		sed 's/ //g' | \
		sed "s/{{[^-}}]*}}/$LOCAL_MODDELIMF/g" | \
		sed "s/{{[^}}]*}}/$LOCAL_MODDELIMB/g")"

	echo -e "$STATUSLINE\n"
}


# Only operates on single monlines
UpdateModuleText() {
	LOCAL_MODULE_CONTENTS="$1"
	MODULE="$2"

	# Replace text with eval call
	LOCAL_MODULE_CONTENTS="$(echo $LOCAL_MODULE_CONTENTS | \
		sed "s/\({{Module$MODULE}}\).*\({{Module$MODULE-}}\)/\1\$($MODULE)\2/")"

	LOCAL_MODULE_CONTENTS="$(InsertMonNums "$LOCAL_MODULE_CONTENTS" "$MODULE")"

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
CleanAsync "$ASYNC" "$MODULES"
InitFifos "$MODULES"

test -z "$DEFINTERVAL" && DEFINTERVAL=10


# ------------------------------------------
# Main Loop
# ------------------------------------------
# Reload config files on signal
trap "Configure; PrintStatus $MODULE_CONTENTS $MODDELIMF $MODDELIMB" SIGUSR1
# from gitlab.com/mellok1488/dotfiles/panel, should kill all sleeps, etc.
trap 'trap - TERM; CleanFifos; kill 0' INT TERM QUIT EXIT

MODULE_CONTENTS="$(InitStatus "$MODULES")"
PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"

while read line; do
	# $line is a module name
	if test "$line" != "All"; then
		# Replace module text with new calls, then eval
		MODULE_CONTENTS="$(UpdateModuleText "$MODULE_CONTENTS" "$line")"
	else
		MODULE_CONTENTS="$(InitStatus "$MODULES")"
	fi

	PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"
done
