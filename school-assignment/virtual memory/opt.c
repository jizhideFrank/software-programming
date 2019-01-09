#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include "pagetable.h"


extern int memsize;

extern int debug;

extern struct frame *coremap;

int MAXLINE = 256;

// need this to get the future reference information
extern char *tracefile;

// record the size of the trace file
int size = 0;
// a array of traced virtual address
addr_t *trace_array;
// the hashtable for look up
struct sec_level_head *hashtable;
// track the trace
int current_position = 0;

struct value{
	// total number of references in the trace file
	int total_refs;
	// a list of future locations
	int *positions;
	// track the current udpates in the reference positions
	int cur_index;
};

struct sec_level_head{
	// indicator to free the sub level
	int total_refs;
	struct value *sub_array;
};

//helper function headers
void make_trace_array(FILE *fd);
void get_entries(addr_t *dir_entry, addr_t *pte_entry, int offset);
void make_hashtable();
void track_vaddr();

/*wrapper function for fseek*/
int Fseek(FILE *stream, long int offset, int whence){
	int result = fseek(stream, offset, whence);
	if (result != 0){
		perror("failed on fseek");
		exit(1);
	}
	return result;
}
/*wrapper function for fopen*/
FILE *Fopen(const char *filename, const char *mode){
	FILE *fd;
	if((fd = fopen(filename, mode)) == NULL) {
		perror("failed on fopen");
		exit(1);
	}
	return fd;
}
/*wrapper function for malloc*/
void *Malloc(size_t size){
	void *result;
	if ((result = malloc(size)) == NULL){
		perror("failed on Malloc");
		exit(1);
	}
	return result;
}
/*wrapper function for calloc*/
void *Calloc(size_t nitem, size_t size){
	void *result;
	if ((result = calloc(nitem, size)) == NULL){
		perror("failed on calloc call");
		exit(1);
	}
	return result;
}
/*wrapper function for fclose*/
int Fclose(FILE *stream){
	int result = fclose(stream);
	if (result == EOF){
		perror("failed on fclose");
		exit(1);
	}
	return result;
}

/* Page to evict is chosen using the optimal (aka MIN) algorithm. 
 * Returns the page frame number (which is also the index in the coremap)
 * for the page that is to be evicted.
 */
int opt_evict() {
	// complexity: O(m), where m is the size of the coremap
	int victim = 0;
	int max = 0;
	for(int frame = 0; frame < memsize; frame++){
		struct frame block = coremap[frame];
		int next_pos = block.next_position;
		
		// case1: no more pages down the trace
		if(next_pos == -1){
			return frame;
		}
		
		int elapse = next_pos - current_position;
		if(elapse > max){
			max = elapse;
			victim = frame;
		}
	}
	return victim;
}

/* This function is called on each access to a page to update any information
 * needed by the opt algorithm.
 * Input: The page table entry for the page that is being accessed.
 */
void opt_ref(pgtbl_entry_t *p) {
	// complexity: O(1)
	
	addr_t vaddr = trace_array[current_position];
	int frame = p->frame >> PAGE_SHIFT;

	struct sec_level_head *sub_head = &(hashtable[PGDIR_INDEX(vaddr)]);
	struct value *current = &((sub_head->sub_array)[PGTBL_INDEX(vaddr)]);

	// update next_position
	(current->cur_index)++;

	// free up the block if necessary
	if(current->cur_index == current->total_refs){
		// indicates that no more reference later on for evict
		coremap[frame].next_position = -1;
		(sub_head->total_refs)--;
		// free the positions array
		free(current->positions);
	}else{
		coremap[frame].next_position = (current->positions)[current->cur_index];
	}
	// free the secondary page table entry if necessary
	if(sub_head->total_refs == 0){
		free(sub_head->sub_array);
	}
	current_position++;
	// free the hashtable at the end
	if(current_position == size){
		free(hashtable);
	}
	return;
}

/* Initializes any data structures needed for this
 * replacement algorithm.
 */
void opt_init() {
	// complexity O(4m) = O(m), where m is the size of the tracefile

	FILE *fd = Fopen(tracefile, "r");

	make_trace_array(fd);
	Fclose(fd);

	make_hashtable();
	track_vaddr();
}



void make_trace_array(FILE *fd){
	char buf[MAXLINE];
	addr_t vaddr = 0;
	char type;
	
	// get the total size of the trace file
	while(fgets(buf, MAXLINE, fd) != NULL){
		if(buf[0] != '='){
			size++;
		}
	}
	trace_array = Calloc(size, sizeof(addr_t));
	// go back to beginning of the file and record each virtual address into the array
	Fseek(fd, 0, SEEK_SET);
	int index = 0;
	while(fgets(buf, MAXLINE, fd) != NULL){
		if(buf[0] != '='){
			sscanf(buf, "%c %lx", &type, &vaddr);
			// get rid of the offset
			trace_array[index++] = vaddr;
		}
	}
}

// record the offsets in the file for each unique virtual address
void track_vaddr(){
	// update the position array in each entry
	for(int offset = 0; offset < size; offset++){

		addr_t dir_entry, pte_entry;
		get_entries(&dir_entry, &pte_entry, offset);

		// initialize the positions array if needed
		struct value *entry = &(((hashtable[dir_entry]).sub_array)[pte_entry]);
		if(entry->positions == NULL){
			entry->positions = Malloc(sizeof(int) * entry->total_refs);
		}
		(entry->positions)[entry->cur_index] = offset;
		(entry->cur_index)++;
		// reset the index at the end
		if(entry->cur_index == entry->total_refs){
			entry->cur_index = 0;
		}
	}
}

/*get the directory index and the secondary page table index from the virtual address*/
void get_entries(addr_t *dir_entry, addr_t *pte_entry, int offset){
	// entire virtual address from the file
	addr_t vaddr = trace_array[offset];
	// get first level of hashtable index
	*dir_entry = PGDIR_INDEX(vaddr);
	// get the second level of hashtable index
	*pte_entry = PGTBL_INDEX(vaddr);
}

/*
 * making a two level hash table (like the two level page table)
 */
void make_hashtable(){
	// initialize the first level of the hashtable, each slot store information about the 2nd page table
	hashtable = Calloc(PTRS_PER_PGDIR, sizeof(struct sec_level_head));

	// traverse the trace array
	for(int offset = 0; offset < size; offset++){
		
		addr_t dir_entry, pte_entry;
		get_entries(&dir_entry, &pte_entry, offset);

		struct sec_level_head *sub_entry = &(hashtable[dir_entry]);
		// initialize the second level table at index dir_entry if not exist
		if(sub_entry->sub_array == NULL){
			sub_entry->sub_array = Calloc(PTRS_PER_PGTBL, sizeof(struct value));
		}
		// update the total reference 
		struct value *result = &((sub_entry->sub_array)[pte_entry]);
		// bookkeeping for individual virtual address struct
		(result->total_refs)++;
		// bookkeeping for total number of reference for this head entry on the first level
		(sub_entry->total_refs)++;
	}
}

