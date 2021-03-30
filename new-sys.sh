#!/bin/bash

# Module text is saved in this format:
#	%{l}\n
#	{ModuleName}abcdef{ModuleName-}\n
#	%{c}\n
#	{ModuleName}ghijkl{ModuleName-}\n
#	%{r}\n
#	{ModuleName}mnopqr{ModuleName-}\n
#
# End goal is to output this:
#	printf "%s\n" "%{l}$MODDELIMabcdef$MODDELIM%{c}$MODDELIMghijkl$MODDELIM%{r}$MODDELIMmnopqr$MODDELIM"

UpdateModuleText() {
	# TODO: Check this preserves newlines, etc.
	LOCAL_MODULE_CONTENTS="$1"
	MODULE="$2"
	NEWTEXT="$($MODULE)"

	LOCAL_MODULE_CONTENTS="$(echo -e $LOCAL_MODULE_CONTENTS | \
		sed "s/\({Module$MODULE}\).*\({Module$MODULE-}\)/\1$NEWTEXT\2/")"

	# restore formatting
	LOCAL_MODULE_CONTENTS="$(echo $LOCAL_MODULE_CONTENTS | sed 's/} /}\\n/g' | sed 's/$/\\n/')"

	echo "$LOCAL_MODULE_CONTENTS"
}

# TODO: Front and back MODDELIM
PrintStatus() {
	LOCAL_MODULE_CONTENTS="$1"
	LOCAL_MODDELIM="$2"

	# Replace module tags, enclose module text
	STATUSLINE="$(echo -e $LOCAL_MODULE_CONTENTS | sed 's/{Module.*}\(.*\){Module.*-}/{{\1}}/g')"

	# Replace induced spaces with $LOCAL_MODDELIM
	STATUSLINE="$(echo $STATUSLINE | sed "s/} {/}$LOCAL_MODDELIM{/g" | \
		sed "s/} %/}$LOCAL_MODDELIM%/g" | \
		sed "s/$/$LOCAL_MODDELIM/")"

	# Remove module text enclosers
	STATUSLINE="$(echo $STATUSLINE | sed 's/{{//g' | sed 's/}}//g')"

	printf "%s\n" "$STATUSLINE"
}

InitStatus() {
	LOCAL_MODULES="$1"
	LOCAL_MODULE_CONTENTS=""

	ALIGNMENTS="l c r"
	MODSLIST="$(echo $LOCAL_MODULES | sed 's/\(%{.}\)/\\n\1/g')"
	for ALIGN in $ALIGNMENTS; do
		ALIGNMODS="$(echo -e $MODSLIST | grep "%{$ALIGN}" | sed 's/%{.}//')"

		ALIGN_OUT="%{$ALIGN}\n"
		for ALIGNMOD in $ALIGNMODS; do
			ALIGN_OUT="$ALIGN_OUT{Module$ALIGNMOD}$($ALIGNMOD){Module$ALIGNMOD-}\n"
		done

		LOCAL_MODULE_CONTENTS="$LOCAL_MODULE_CONTENTS$ALIGN_OUT"
	done

	echo "$LOCAL_MODULE_CONTENTS"
}


# TODO:
# MODULES="%{l}Network Bluetooth saraLayout%{c}saraTags%{r}Audio Brightness Network Battery Time"
# How identify which modules are controlled by peachbar-sys?
#	TODO: do %{l}, etc. calls have to happen once?
#		can they happen out-of-order?
#		if so, then modules could just output where they belong!
#	TODO: above doesn't solve signaling issue
#		async goal: sara info does not update at the same time as sys info
#			more generally, all module changes don't mean others have necessarily
#				changed.

# 1. Parse MODULES string into left, center, and righthand
# 2. Evaluate MODULES in order
# 3. Async options:
#	a. Each module forks and runs as its own process, signaling peachbar-sys.sh
#		when it has an update. ew.
#	b. peachbar-signal.sh requires the name of the module being updated.
#		peachbar-sys.sh will save the output string so it can only update the
#		section it gets signaled about. But can't pass along other arguments when
#		signaling.
#	c. peachbar-sys.sh reads from a fifo that tells it what needs updating.
#		basically, a queue of to-dos.
#		peachbar-sys.sh < $PEACHFIFO | lemonbar | sh
#		exec "sara-interceptor.sh $SARAFIFO"
#		i. a version of 3a - sleeps fork off and then write to the fifo when done.
#			peachbar-sys.sh while read line; do's things.
#			if receive "All", then updates entire bar


# ParseSara Module:
#	Must read from the INFF on its own
#	TODO: how does sara writing to the inff trigger an update to the bar?
#		Brute force: every sara sxhkd action also triggers peachbar-signal.sh... ew
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
	# $line is a module name
	test "$line" != "All" && MODULE_CONTENTS="$(UpdateModuleText "$MODULE_CONTENTS" "$line")" || \
		MODULE_CONTENTS="$(InitStatus)"

	PrintStatus "$MODULE_CONTENTS" "$MODDELIM"
done
