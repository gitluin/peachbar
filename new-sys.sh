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

# TODO: Make it clear that you can't have certain strings in your bar text, or else sed will fuck with it

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


# async goal: sara info does not update at the same time as sys info
#	more generally, all module changes don't mean others have necessarily
#		changed.

# 1. Parse MODULES string into left, center, and righthand
# 2. Evaluate MODULES in order
# 3. Async options:
#	c. peachbar-sys.sh reads from a fifo that tells it what needs updating.
#		basically, a queue of to-dos.
#		peachbar-sys.sh < $PEACHFIFO | lemonbar | sh
#		exec "sara-interceptor.sh $SARAFIFO"
#		i. each module has a sleep that forks off and then writes the module name to $PEACHFIFO when done.
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
	# $line is a module name
	test "$line" != "All" && MODULE_CONTENTS="$(UpdateModuleText "$MODULE_CONTENTS" "$line")" || \
		MODULE_CONTENTS="$(InitStatus)"

	PrintStatus "$MODULE_CONTENTS" "$MODDELIM"
done
