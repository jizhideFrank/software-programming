#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include "pagetable.h"


extern int memsize;

extern int debug;

extern struct frame *coremap;

// most recently used page frame
struct frame *head = NULL;
// the frame that need to be evicted
struct frame *tail = NULL;

/* Page to evict is chosen using the accurate LRU algorithm.
 * Returns the page frame number (which is also the index in the coremap)
 * for the page that is to be evicted.
 */
int lru_evict() {
	// evit the tail page
	int frame = 0;
	// get the frame number of the tail page
	frame = (tail->pte->frame) >> PAGE_SHIFT;
	// update the previous pointers
	struct frame *previous_p = tail->previous;

	// case1: linked list of size >= 2
	if(previous_p != NULL){ 
		// update the new tail frame in the linked list
		previous_p->next = NULL;
		// disconnect the frame from the linked list
		tail->previous = NULL;
		// update the next victim page pointer
		tail = previous_p;
	}else{ // linked list of size 1
		head = tail = NULL;
	}
	return frame;
}

/* This function is called on each access to a page to update any information
 * needed by the lru algorithm.
 * Input: The page table entry for the page that is being accessed.
 */
void lru_ref(pgtbl_entry_t *p) {
	// retrieve the current page frame in simulated physical memory
	int frame_num = p->frame >> PAGE_SHIFT;
	struct frame *current = &(coremap[frame_num]);
	// speical cases
	if(!head){
		head = tail = current;
		return;
	}
	// the frame that is referenced is not the head node
	if(current != head){
		// store the previous and the next node relative to the current one
		struct frame *previous_p = current->previous;
		struct frame *next_p = current->next;

		// place the current page to the front of the list as it is the most recently referenced
		current->next = head;
		head->previous = current;
		current->previous = NULL;
		head = current;

		// correct the pointers of the neighbours in the linked list
		if(previous_p){
			previous_p->next = next_p;
		}

		// when the current page is not the tail page in the linked list
		if(next_p){
			next_p->previous = previous_p;
		}
		// edge case: when reference page is the tail
		else if(previous_p){
			tail = previous_p;
		}
	}
	// if the reference is the head node, then the linked list stays the same
	return;
}


/* Initialize any data structures needed for this 
 * replacement algorithm 
 */
void lru_init() {
	for(int i = 0; i < memsize; i++){
		struct frame *current = &(coremap[i]);
		current->previous = NULL;
		current->next = NULL;
	}
}
