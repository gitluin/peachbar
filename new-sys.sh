#!/bin/bash

# Module text is saved in this format:
#	%{S0}%{l}{{ModuleName}}abcdef{{ModuleName-}}%{r}{{ModuleName}}ghijkl{{ModuleName-}}\n
#	%{S1}%{l}{{ModuleName}}mnopqr{{ModuleName-}}%{r}{{ModuleName}}stuvwx{{ModuleName-}}
#
# End goal is to output this:
#	"%{S0}%{l}$MODDELIMFabcdef$MODDELIMB%{r}$MODDELIMFghijkl$MODDELIMB%{S1}%{l}$MODDELIMFmnopqr$MODDELIMB%{r}$MODDELIMFstuvwx$MODDELIMB"
#
# All modules get told what monitor they are on.
# {{.*}} is not permitted inside your bar text, i.e. as module output.
# Most likely, GNU sed is required.


# 3. Async options:
#	c. peachbar-sys.sh reads from a fifo that tells it what needs updating.
#		basically, a queue of to-dos.
#		peachbar-sys.sh < $PEACHFIFO | lemonbar | sh
#		exec "sara-interceptor.sh $SARAFIFO $PEACHFIFO"
#		i. each module has a sleep that forks off and then writes the module name to
#			$PEACHFIFO when done.
#			peachbar-sys.sh while read line; do's things.
#			if receive "All", then updates entire bar
#			if nothing in $PEACHFIFO, no work is done!
#		ii. peachbar-signal.sh should now push updates to $PEACHFIFO, not signal the process
#			TODO: should reset any associated sleep timer

# ParseSara Module:
#	Must read from the INFF on its own
#	How does sara writing to the inff trigger an update to the bar?
#		sara-interceptor.sh while read line; do's $SARAFIFO, and then spits it back
#			into $SARAFIFO and writes to $PEACHFIFO


# TODO: check whole thing
# Generates the inital MODULE_CONTENTS string
InitStatus() {
	LOCAL_MODULES="$1"
	LOCAL_MODULE_CONTENTS=""

	MULTI="$(xrandr -q | grep " connected" | wc -l)"
	for (( i=0; i<$MULTI; i++ )); do
		LOCAL_MODULE_CONTENTS="${LOCAL_MODULE_CONTENTS}%{S$i}"

		ALIGNMENTS="l c r"
		MODSLIST="$(echo $LOCAL_MODULES | sed 's/\(%{.}\)/\\n\1/g')"

		for ALIGN in $ALIGNMENTS; do
			ALIGNMODS="$(echo -e $MODSLIST | grep "%{$ALIGN}" | sed 's/%{.}//')"

			ALIGN_OUT="%{$ALIGN}"
			for ALIGNMOD in $ALIGNMODS; do
				ALIGN_OUT="$ALIGN_OUT{{Module$ALIGNMOD}}$($ALIGNMOD "$i"){{Module$ALIGNMOD-}}"
			done

			LOCAL_MODULE_CONTENTS="${LOCAL_MODULE_CONTENTS}$ALIGN_OUT"
		done
		
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
MODULE_CONTENTS="$(InitStatus)"
PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"


# ------------------------------------------
# Main Loop
# ------------------------------------------
while read line; do
	MULTI="$(xrandr -q | grep " connected" | wc -l)"

	# $line is a module name
	if test "$line" != "All"; then
		for (( i=0; i<$MULTI; i++ )); do
			# TODO: test
			MON_MODULE_CONTENTS="$(echo -e $MODULE_CONTENTS | grep "%{S$i}")"
			MON_MODULE_CONTENTS="$(UpdateModuleText "$MON_MODULE_CONTENTS" "$line" $i)"

			# overwrite old monline with new monline
			MODULE_CONTENTS="$(echo -e $MODULE_CONTENTS | \
				sed "s/%{S$i}.*/%{S$i}$MON_MODULE_CONTENTS/")"

			# TODO: restore formatting

			#TO_OUT="${TO_OUT}%{B$BARBG}%{S$i}${STATUSLINE}%{B-}"
		done
	else
		MODULE_CONTENTS="$(InitStatus)"

	fi

	# TODO: strip newlines before passing to PrintStatus
	PrintStatus "$MODULE_CONTENTS" "$MODDELIMF" "$MODDELIMB"
done
