#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define N 10000
#define PAGESIZE 4096 

int main(int argc, char const *argv[])
{
	/* Markers used to bound trace regions of interest */
	volatile char MARKER_START, MARKER_END;
	/* Record marker addresses */
	FILE* marker_fp = fopen("test.marker","w");
	if(marker_fp == NULL ) {
		perror("Couldn't open marker file:");
		exit(1);
	}
	fprintf(marker_fp, "%p %p", &MARKER_START, &MARKER_END );
	fclose(marker_fp);


    int *mem = malloc(N*PAGESIZE*sizeof(int));
    if (!mem) 
        return 1;

    int counter = 1;

    MARKER_START = 33;
	while(counter <= 2){
		for(int i = 0; i < N; i++){
			mem[i*PAGESIZE] = 1;
		}
		counter ++;
	}
    MARKER_END = 34;
    
    return 0;
}
