#!/bin/bash

# Module text is saved in this format:
#	%{S0}%{l}{{ModuleName}}abcdef{{ModuleName-}}%{r}{{ModuleName}}ghijkl{{ModuleName-}}\n
#	%{S1}%{l}{{ModuleName}}mnopqr{{ModuleName-}}%{r}{{ModuleName}}stuvwx{{ModuleName-}}
#
# End goal is to output this:
#	"%{S0}%{l}$MODDELIMabcdef$MODDELIM%{r}$MODDELIMghijkl$MODDELIM%{S1}%{l}$MODDELIMmnopqr$MODDELIM%{r}$MODDELIMstuvwx$MODDELIM"

# TODO: Make it clear that you can't have certain strings in your bar text, or else sed will fuck with it
# TODO: Make it clear that this most likely requires GNU sed

# Only operates on single monlines
UpdateModuleText() {
	LOCAL_MODULE_CONTENTS="$1"
	MODULE="$2"
	NEWTEXT="$($MODULE "$3")"

	LOCAL_MODULE_CONTENTS="$(echo $LOCAL_MODULE_CONTENTS | \
		sed "s/\({{Module$MODULE}}\).*\({{Module$MODULE-}}\)/\1$NEWTEXT\2/")"

	echo "$LOCAL_MODULE_CONTENTS"
}


# TODO: how does monitor-dependent output get treated? Say, for ParseSara?
# 	TODO: Preferably without special treatment, i.e. as if it were any other module
# 	Do all modules get told what monitor they are on?


# TODO: Front and back MODDELIM
#	Just separate sed calls with [^-}}]}} and [^}}]}}
PrintStatus() {
	LOCAL_MODULE_CONTENTS="$1"
	LOCAL_MODDELIM="$2"

	# Replace {{ModuleName}} and {{ModuleName-}} tags with $MODDELIMS
	STATUSLINE="$(echo "$LOCAL_MODULE_CONTENTS" | sed "s/{{[^}}]*}}/$LOCAL_MODDELIM/g")"

	printf "%s\n" "$STATUSLINE"
}

# TODO: update for new multihead format
InitStatus() {
	LOCAL_MODULES="$1"
	LOCAL_MODULE_CONTENTS=""

	ALIGNMENTS="l c r"
	MODSLIST="$(echo $LOCAL_MODULES | sed 's/\(%{.}\)/\\n\1/g')"
	for ALIGN in $ALIGNMENTS; do
		ALIGNMODS="$(echo -e $MODSLIST | grep "%{$ALIGN}" | sed 's/%{.}//')"

		ALIGN_OUT="%{$ALIGN}"
		for ALIGNMOD in $ALIGNMODS; do
			ALIGN_OUT="$ALIGN_OUT{{Module$ALIGNMOD}}$($ALIGNMOD){{Module$ALIGNMOD-}}"
		done

		LOCAL_MODULE_CONTENTS="$LOCAL_MODULE_CONTENTS$ALIGN_OUT"
	done

	echo "$LOCAL_MODULE_CONTENTS"
}


# async goal: sara info does not update at the same time as sys info
#	more generally, all module changes don't mean others have necessarily
#		changed.

# 1. Parse MODULES string into left, center, and righthand
# 2. Evaluate MODULES in order
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


# ------------------------------------------
# Initialization
# ------------------------------------------
MODULE_CONTENTS="$(InitStatus)"
PrintStatus "$MODULE_CONTENTS" "$MODDELIM"


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

			TO_OUT="${TO_OUT}%{B$BARBG}%{S$i}${STATUSLINE}%{B-}"
		done
	else
		MODULE_CONTENTS="$(InitStatus)"
	fi

	PrintStatus "$MODULE_CONTENTS" "$MODDELIM"
done
