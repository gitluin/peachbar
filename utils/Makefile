PREFIX?= /usr/local
BINDIR?= $(PREFIX)/bin

CFLAGS= -std=c99 -Wall -Wno-deprecated-declarations -D_POSIX_C_SOURCE=200809L -Os

SRC= peachbar-timer.c
OBJ= ${SRC:.c=.o}

all: peachbar-timer

.c.o:
	${CC} -c ${CFLAGS} $<

peachbar-timer: ${OBJ}
	${CC} -o $@ ${OBJ}

install: all
	install -Dm 755 peachbar-timer $(BINDIR)/peachbar-timer

uninstall:
	rm -f $(BINDIR)/peachbar-timer

clean:
	rm -f peachbar-timer *.o
