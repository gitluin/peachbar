#!/bin/bash

# TODO: when all is said and done, consider converting to a C program instead
#	Modules, etc. can be offloaded to linked lists
#	Config parsing becomes a pain in the ass

# Modules are specified by the user with lemonbar syntax in a string:
#	"%{S0}%{l}ModuleName ModuleName%{c}ModuleName%{r}ModuleName%{S1}%{l}ModuleName ModuleName%{c}ModuleName ModuleName%{r}"
#
# Module text is saved by peachbar in this format as MODULE_CONTENTS:
#	%{S0}%{l}{{ModuleName}}xxx{{ModuleName-}}%{r}{{ModuleName}}yyy{{ModuleName-}}\n
#	%{S1}%{l}{{ModuleName}}zzz{{ModuleName-}}%{r}{{ModuleName}}uuu{{ModuleName-}}
#
# End goal is to output this STATUSLINE to lemonbar:
#	%{S0}%{l}$MODDELIMFxxx$MODDELIMB%{r}$MODDELIMFyyy$MODDELIMB%{S1}%{l}$MODDELIMFzzz$MODDELIMB%{r}$MODDELIMFuuu$MODDELIMB
#
# All modules get told what monitor they are on.
# {{.*}}, %{S[0-9]}, and %{l/c/r} are not permitted inside your bar text,
#	i.e. as module output, or as a module name. You'll screw up bar text parsing.
# Most likely, GNU sed is required.


# Async:
# peachbar-sys.sh reads from a fifo that tells it what needs updating.
# 	basically, a queue of to-dos.
# 	peachbar-sys.sh < $PEACHFIFO | lemonbar | sh &
# 	exec "sara-interceptor.sh $SARAFIFO $PEACHFIFO"
# 	i. each module has a sleep that forks off and then writes the module name to
# 		$PEACHFIFO when done.
# 		peachbar-sys.sh while read line; do's things.
# 		if receive "All", then updates entire bar
# 		if nothing in $PEACHFIFO, no work is done!
# 	ii. peachbar-signal.sh should now push updates to $PEACHFIFO, not signal the process
# 		Each module gets its own fifo? peachbar-ModuleName.fifo?
# 			each module writes its sleep pid to its fifo when on a timer
# 			peachbar-signal.sh reads sleep pid from peachbar-ModuleName.fifo, and
# 				kills it. killing it will trigger the subsequent echo. the bar update
# 				will automatically set a new timer.


# TODO: better options for wal integration in case colors are shite
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


# TODO: Build up another string with Y/N for async status:
#        %{S0}%{l}Y%{c}N\n
#        %{S1}%{l}Y%{c}N


EvalModule() {
	MODULENAME=$1
	MODULEASYNC=$2
	MONNUM=$3
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


# ParseSara Module:
#	Must read from the INFF on its own
#		TODO: this conflicts with the idea of running the module twice for each
#			monitor, since reading will swallow the line
#			TODO: outputstats() in sara.c should output one line per monitor, and
#				identify the monitor at the beginning of the line
#				TODO: this will cause "sara" > $PEACHFIFO twice, though, which doesn't
#					jive with how this should be updating.
#				TODO: what if sara could reply with information when asked, *or* write to
#					fifo?
#	How does sara writing to the inff trigger an update to the bar?
#		sara-interceptor.sh while read line; do's $SARAFIFO, and then spits it back
#			into $SARAFIFO and writes to $PEACHFIFO


CleanFifos() {
	PEACHFIFOS="$(ls "/tmp/" | grep "peachbar")"
	for TO_DEL in "$PEACHFIFOS"; do
		sudo rm "$TO_DEL"
	done
}


InitFifos() {
	LOCAL_MODULES="$1"
	ALIGNMENTS="l c r"

	MULTI="$(( $(xrandr --listactivemonitors | wc -l) - 1))"
	for (( i=0; i<$MULTI; i++ )); do
		if test $i -eq $(($MULTI - 1)); then
			MON_MODULES="$(echo $LOCAL_MODULES | sed "s/.*\(%{S$i}.*\)/\1/")"
		else
			MON_MODULES="$(echo $LOCAL_MODULES | sed "s/.*\(%{S$i}.*\)%{S$(($i + 1))}.*/\1/")"
		fi

		MODSLIST="$(echo $MON_MODULES | sed 's/\(%{[^}]*}\)/\\n\1/g')"

		for ALIGN in $ALIGNMENTS; do
			ALIGNMODS="$(echo -e $MODSLIST | grep "%{$ALIGN}" | sed 's/%{.}//')"

			ALIGN_OUT="%{$ALIGN}"
			for ALIGNMOD in $ALIGNMODS; do
				MODFIFO="/tmp/peachbar-Module$ALIGNMOD.fifo"
				test -e "$MODFIFO" && ! test -p "$MODFIFO" && sudo rm "$MODFIFO"
				test -p "$MODFIFO" || sudo mkfifo -m 777 "$MODFIFO"
			done
		done
	done
}


# TODO: check whole thing with dummy module output
# Generates the inital MODULE_CONTENTS string
InitStatus() {
	LOCAL_MODULES="$1"
	LOCAL_MODULE_CONTENTS=""
	ALIGNMENTS="l c r"

	MULTI="$(( $(xrandr --listactivemonitors | wc -l) - 1))"
	for (( i=0; i<$MULTI; i++ )); do
		LOCAL_MODULE_CONTENTS="${LOCAL_MODULE_CONTENTS}%{S$i}%{B$BARBG}"

		if test $i -eq $(($MULTI - 1)); then
			MON_MODULES="$(echo $LOCAL_MODULES | sed "s/.*\(%{S$i}.*\)/\1/")"
		else
			MON_MODULES="$(echo $LOCAL_MODULES | sed "s/.*\(%{S$i}.*\)%{S$(($i + 1))}.*/\1/")"
		fi

		MODSLIST="$(echo $MON_MODULES | sed 's/\(%{[^}]*}\)/\\n\1/g')"

		for ALIGN in $ALIGNMENTS; do
			ALIGNMODS="$(echo -e $MODSLIST | grep "%{$ALIGN}" | sed 's/%{.}//')"

			ALIGN_OUT="%{$ALIGN}"
			for ALIGNMOD in $ALIGNMODS; do
				MODFIFO="/tmp/peachbar-Module$ALIGNMOD.fifo"
				test -e "$MODFIFO" && ! test -p "$MODFIFO" && sudo rm "$MODFIFO"
				test -p "$MODFIFO" || sudo mkfifo -m 777 "$MODFIFO"

				# TODO: use EvalModule instead
				ALIGN_OUT="$ALIGN_OUT{{Module$ALIGNMOD}}$($ALIGNMOD "$i"){{Module$ALIGNMOD-}}"
			done

			LOCAL_MODULE_CONTENTS="${LOCAL_MODULE_CONTENTS}$ALIGN_OUT"
		done

		LOCAL_MODULE_CONTENTS="${LOCAL_MODULE_CONTENTS}%{B-}"
		
		# If not last, add newline
		if test $((i + 1)) -ne $MULTI; then
			LOCAL_MODULE_CONTENTS="${LOCAL_MODULE_CONTENTS}\n"
		fi
	done

	echo "$LOCAL_MODULE_CONTENTS"
}


# Prints MODULE_CONTENTS to lemonbar, adding in module delimeters
PrintStatus() {
	LOCAL_MODULE_CONTENTS="$1"
	LOCAL_MODDELIMF="$2"
	LOCAL_MODDELIMB="$3"

	# Replace {{ModuleName}} and {{ModuleName-}} tags with $MODDELIMS
	# [^-}}] and [^}}] prevent greedy matching
	STATUSLINE="$(echo "$LOCAL_MODULE_CONTENTS" | \
		sed "s/{{[^-}}]*}}/$LOCAL_MODDELIMF/g" | \
		sed "s/{{[^}}]*}}/$LOCAL_MODDELIMB/g")"

	echo -e "$STATUSLINE\n"
}


# Only operates on single monlines
UpdateModuleText() {
	LOCAL_MODULE_CONTENTS="$1"
	MODULE="$2"
	NEWTEXT="$($MODULE "$3")"

	LOCAL_MODULE_CONTENTS="$(echo $LOCAL_MODULE_CONTENTS | \
		sed "s/\({{Module$MODULE}}\).*\({{Module$MODULE-}}\)/\1$NEWTEXT\2/")"

	echo "$LOCAL_MODULE_CONTENTS"
}


# ------------------------------------------
# Initialization
# ------------------------------------------
# Kill zombie peachbar-sys.sh instances
PEACHPIDS="$(pgrep "peachbar-sys")"
for PEACHPID in $PEACHPIDS; do
	! test $PEACHPID = $$ && kill -9 $PEACHPID
done

Configure
InitFifos "$MODULES"

MODULE_CONTENTS="$(InitStatus "$MODULES")"
PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"


# ------------------------------------------
# Main Loop
# ------------------------------------------
# Reload config files on signal
trap "Configure" SIGUSR1
# from gitlab.com/mellok1488/dotfiles/panel, should kill all sleeps, etc.
trap 'trap - TERM; CleanFifos; kill 0' INT TERM QUIT EXIT
while read line; do
	# TODO: lemonbar-equivalent monitor detection
	#	lemonbar offloads to randr when detected, XINERAMA otherwise
	#	xrandr --list-monitors?
	MULTI="$(( $(xrandr --listactivemonitors | wc -l) - 1))"

	# $line is a module name
	if test "$line" != "All"; then
		for (( i=0; i<$MULTI; i++ )); do
			MON_MODULE_CONTENTS="$(echo -e $MODULE_CONTENTS | grep "%{S$i}")"
			MON_MODULE_CONTENTS="$(UpdateModuleText "$MON_MODULE_CONTENTS" "$line" $i)"

			# overwrite old monline with new monline
			# MON_MODULE_CONTENTS already contains %{S$i}
			MODULE_CONTENTS="$(echo -e "$MODULE_CONTENTS" | \
				sed "s/%{S$i}.*/$MON_MODULE_CONTENTS/")"

			# restore formatting
			MODULE_CONTENTS="$(echo $MODULE_CONTENTS | sed 's/ \(%{S.}\)/\\n\1/g')"
		done
	else
		MODULE_CONTENTS="$(InitStatus "$MODULES")"
	fi

	TO_OUT="$(echo "$MODULE_CONTENTS" | sed 's/\\n//g')"
	PrintStatus "$TO_OUT" "$MODDELIMF" "$MODDELIMB"
done
