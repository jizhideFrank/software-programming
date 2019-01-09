#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include "pagetable.h"


extern int memsize;

extern int debug;

extern struct frame *coremap;


// global variable to store the current clock position
int current_frame = 0;

/* Page to evict is chosen using the clock algorithm.
 * Returns the page frame number (which is also the index in the coremap)
 * for the page that is to be evicted.
 */
int clock_evict() {
	while(1){
		unsigned int current = (coremap[current_frame].pte)->frame;
		// get the page table entry
		int referenced = current & PG_REF;
		// if the physical frame is not referenced, it is a victim page
		if(!referenced){
			int victim_frame = current_frame;
			// advanced one position
			current_frame = (current_frame + 1) % memsize;
			return victim_frame;
		}
		// reset the reference bit to give the page a second chance
		(coremap[current_frame].pte)->frame = current & ~PG_REF;
		// update the clock arm position in the array
		current_frame = (current_frame + 1) % memsize;
	}
	// should never reaches here
	return 0;
}

/* This function is called on each access to a page to update any information
 * needed by the clock algorithm.
 * Input: The page table entry for the page that is being accessed.
 */
void clock_ref(pgtbl_entry_t *p) {

	return;
}

/* Initialize any data structures needed for this replacement
 * algorithm. 
 */
void clock_init() {
}
