#!/bin/sh

# TODO: trap for killing things
SARAFIFO="$1"
PEACHFIFO="$2"

Interceptor(){
	while read line; do
		echo "$line" > $SARAFIFO
		echo "sara" > $PEACHFIFO
	done
}

sara > $SARAFIFO &

Interceptor < $SARAFIFO
