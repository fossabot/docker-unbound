#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

char *unbound = "/usr/bin/unbound";
char *unbound_anchor = "/usr/bin/unbound-anchor";
char *anchor_args[] = {"unbound-anchor", "-v", "-r", "/etc/unbound/named.root", NULL};

int main() {

	printf("Refreshing DNSSEC root key files...\n");
	if(fork() == 0) {
		setuid(1001);
		setgid(1001);
		return execv(unbound_anchor, anchor_args);
	}
	wait(NULL);
		
	printf("Done!\nStarting Unbound...\n");	
	return execl(unbound, "", NULL);	
}