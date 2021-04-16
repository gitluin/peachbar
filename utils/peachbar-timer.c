#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

#define MAXBUF 		38

int
slen(const char* str){
	int i = 0;

	while (*str){ str++; i++; }

	return i;
}

void
usage(){
	printf("Usage: peachbar-timer ModuleName Interval ModuleFifo PeachFifo\n");
	printf("\n");
	printf("  Utility function for peachbar that forks timers for modules.\n");
	printf("  String length is limited to 37 characters (not including \\0).\n");
}

int
main(int argc, char* argv[]){
	// argv[0] 
	// argv[1] ModuleName
	// argv[2] Interval
	// argv[3] ModuleFifo
	// argv[4] PeachFifo
	int interval, sleep_pid, fint;
	char module_name[MAXBUF], module_file[MAXBUF], peach_fifo[MAXBUF], msg[MAXBUF], tmp[MAXBUF];

	if (argc != 5){
		usage();
		return 0;
	}

	snprintf(module_name, MAXBUF, "%s\n", argv[1]);
	snprintf(tmp, MAXBUF, "%s\n", argv[2]);
	interval = atoi(tmp);
	snprintf(module_file, MAXBUF, "%s\n", argv[3]);
	snprintf(peach_fifo, MAXBUF, "%s\n", argv[4]);
	
	sleep_pid = fork();
	if (sleep_pid == 0){
		setsid();
		sleep(interval);
		// TODO: try until you can write
		fint = open(peach_fifo, O_WRONLY);
		write(fint, module_name, slen(module_name));
		close(fint);
		exit(EXIT_SUCCESS);
		
	} else {
		sprintf(msg, "%d\n", sleep_pid);

		fint = open(module_file, O_WRONLY);
		write(fint, msg, slen(msg));
		close(fint);
	}

	return 0;
}
