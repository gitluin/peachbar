#!/bin/bash


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
#		section it gets signaled about.
#		TODO: what happens with simultaneous signaling for two separate modules?
#		TODO: how does sara writing to the inff trigger peachbar-signal.sh?
#			Brute force: every sara sxhkd action also triggers peachbar-signal.sh... ew


# ParseSara Module:
#	Must read from the INFF on its own

TO_OUT=""

ALIGNMENTS="l c r"
MODSLIST="$(echo $MODULES | sed 's/\(%{.}\)/\\n\1/g')"
for ALIGN in $ALIGNMENTS; do
	ALIGNMODS="$(echo -e $MODSLIST | grep "%{$ALIGN}" | sed 's/%{.}//')"

	ALIGN_OUT="%{$ALIGN}"
	for ALIGNMOD in $ALIGNMODS; do
		ALIGN_OUT="$ALIGN_OUT$($ALIGNMOD)"
	done

	TO_OUT="$TO_OUT$ALIGN_OUT"
done
