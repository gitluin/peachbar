#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#define MAXBUF 		39

// TODO: explain rammifications of MAXBUF, i.e. on max timer value (seconds)

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
	/* argv[0] 
	 * argv[1] do_execvp
	 * argv[2] ModuleName
	 * argv[3] Interval
	 * argv[4] ModuleFifo
	 * argv[5] PeachFifo
	 */
	int do_execvp, interval, sleep_pid, fint;
	char module_name[MAXBUF], module_file[MAXBUF], peach_fifo[MAXBUF], msg[MAXBUF], tmp[MAXBUF];
	struct timespec timer, ret;
	timer.tv_sec = 0;
	timer.tv_nsec = 1000000L;

	if (argc != 6){
		usage();
		return 0;
	}

	snprintf(tmp, MAXBUF, "%s", argv[1]);
	do_execvp = atoi(tmp);

	/* If initial call, execvp to truly detach */
	if (do_execvp){
		argv[1] = "0";
		// TODO: not that safe
		execvp(argv[0], argv);
		perror("peachbar-timer: internal execvp failed");
	}

	snprintf(module_name, MAXBUF, "%s\n", argv[2]);
	snprintf(tmp, MAXBUF, "%s\n", argv[3]);
	interval = atoi(tmp);
	snprintf(module_file, MAXBUF, "%s", argv[4]);
	snprintf(peach_fifo, MAXBUF, "%s", argv[5]);
	
	sleep_pid = fork();
	if (sleep_pid == 0){
		setsid();
		sleep(interval);

		/* sleep for 1 ms, try again */
		while ((fint = open(peach_fifo, O_WRONLY)) < 0){
			nanosleep(&timer, &ret);
		}
		write(fint, module_name, slen(module_name));
		close(fint);
		exit(EXIT_SUCCESS);
		
	} else {
		sprintf(msg, "%d\n", sleep_pid);

		/* Shouldn't have anyone else trying to open the file */
		fint = open(module_file, O_WRONLY);
		write(fint, msg, slen(msg));
		close(fint);
	}

	return 0;
}
