#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
#include "ext2_utils.h"

/*
 * get the disk image from the file descriptor table
 * */
void get_disk_image(int fd){
    // 128 blocks inside the disk each block of EXT2_BLOCK_SIZE bytes of memory size
    disk = mmap(NULL, 128 * EXT2_BLOCK_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if(disk == MAP_FAILED) {
        perror("mmap");
        exit(-1);
    }
}

struct ext2_super_block *get_super_block(){
    return (struct ext2_super_block *)(disk + EXT2_BLOCK_SIZE);
}

struct ext2_group_desc *get_block_descriptor_table(){
    return (struct ext2_group_desc *)(disk + (EXT2_BLOCK_SIZE * 2));
}

struct ext2_inode *get_inode_table(){
    struct ext2_group_desc *g = get_block_descriptor_table();
    return (struct ext2_inode *)(disk + EXT2_BLOCK_SIZE * g->bg_inode_table);
}

unsigned char *get_block_bitmap(){
    struct ext2_group_desc *g = get_block_descriptor_table();
    return (unsigned char *)(disk + (EXT2_BLOCK_SIZE * g->bg_block_bitmap));
}

unsigned char *get_inode_bitmap(){
	struct ext2_group_desc *g = get_block_descriptor_table();
    return (unsigned char *)(disk + (EXT2_BLOCK_SIZE * g->bg_inode_bitmap));
}


//TODO: check if the shift amount is correct
int valid_data_block_entry(unsigned int block_num){
    block_num--;
    int i = block_num / 8;
    int bit_in_byte = block_num % 8;
    if(data_block_bitmap[i] & (1 << bit_in_byte)){
        return 1;
    }
    return 0;
}

int valid_inode_entry(unsigned int inode_num){
    inode_num--;
    int i = inode_num / 8;
    int bit_in_byte = inode_num % 8;
    if(inode_block_bitmap[i] & (1 << bit_in_byte)){
        return 1;
    }
    return 0;
}

/**
 * make sure the path is absolute path and no trailing slashes
 */
void is_absolute_path(char *path){
    if (path[0] != '/'){
        exit(-EINVAL);
    }
}

/**
 * get an **array** of indirect datablocks from the inode index
 * inode_ii is the inode index inside the inode table
 */
void get_indirect_blocks(int inode_ii, unsigned int **indirect_blocks){
    
    struct ext2_inode *inode = &inode_table[inode_ii];
    int indirect_bn = inode->i_block[DIRECT_BLOCK_ENTRIES];
    // get the address on the image
    *indirect_blocks = (unsigned int *)(disk + EXT2_BLOCK_SIZE * indirect_bn);
}

void reset_in_bitmap(unsigned int block_num, unsigned char *bitmap){
    block_num--;
    int i = block_num / 8;
    int bit_in_byte = block_num % 8;
    bitmap[i] &= ~(1 << bit_in_byte);

    // compare the address and decides the bookkeeping parameters
    if (bitmap == inode_block_bitmap){
        sb->s_free_inodes_count += 1;
        gb->bg_free_inodes_count += 1;
    }else{
        sb->s_free_blocks_count += 1;
        gb->bg_free_blocks_count += 1;
    }
}

void set_in_bitmap(unsigned int block_num, unsigned char *bitmap){
    block_num--;
    int i = block_num / 8;
    int bit_in_byte = block_num % 8;
    bitmap[i] |= (1 << bit_in_byte);

    //TODO: bookkeeping super block and group descriptor
    if (bitmap == inode_block_bitmap){
        sb->s_free_inodes_count -= 1;
        gb->bg_free_inodes_count -= 1;
    }else{
        sb->s_free_blocks_count -= 1;
        gb->bg_free_blocks_count -= 1;
    }
}

void get_null_terminated_name(char **null_terminate_name, char *name, int name_length){
    strncpy(*null_terminate_name, name, name_length);
    (*null_terminate_name)[name_length] = '\0';
}

/**
 * check the bit at pos in byte free
 * return 0 if not
*/
int is_free_bit(unsigned char byte, int pos){
    if ((byte & (1 << pos)) == 0){
        return 1;
    }
    return 0;
}

/**
 * return the first free bit from the provided byte
 * return -1 if no free bit exist in the current byte
*/
int check_free_bit_from_byte(unsigned char byte){
    // perfrom the bit mask in a reverse way
    for (int i = 0; i <= 7; i++) {
        if (is_free_bit(byte, i)){
            return i;
        }
    }
    return -1;
}

/**
 * make the next availbel data block valid if there are any;
 * exit with error code if no more space in the data block region
 *
 * return the data block number
*/
unsigned int make_nxt_data_block_valid(){
    // find the next available block
    for(int i = 0; i < sb->s_blocks_count; i++){
        unsigned char slot = data_block_bitmap[i];
        int free_bit_pos;
        if((free_bit_pos = check_free_bit_from_byte(slot)) >= 0){
            // set the bit at that position
            data_block_bitmap[i] |= (1 << free_bit_pos);

            // bookkeeping on superblock and group descriptor
            sb->s_free_blocks_count -= 1;
            gb->bg_free_blocks_count -= 1;

            return (i * 8) + free_bit_pos + 1;
        }
    }
    exit(-ENOSPC);
}

/**
 * make the next available inode valid if there are any;
 * exit with error code if no more space in the inode table
 *
 * return the inode **number**
*/
unsigned int make_nxt_inode_valid(){

    // find the next available block
    for(int i = 0; i < sb->s_inodes_count / 8; i++){
        unsigned char slot = inode_block_bitmap[i];
        int free_bit_pos;
        if((free_bit_pos = check_free_bit_from_byte(slot)) >= 0){
            // set the bit at that position
            inode_block_bitmap[i] |= (1 << free_bit_pos);

            // bookkeeping on superblock and group descriptor
            sb->s_free_inodes_count -= 1;
            gb->bg_free_inodes_count -= 1;
            return (i * 8) + free_bit_pos + 1;
        }
    }
    exit(-ENOSPC);
}

/**
 * make the current number in four bytes boundary
*/
int make_four_byte_boundary(int current){
    while(current % 4 != 0){
        current++;
    }
    return current;
}

/**
 * return the destination name of the path
*/
char *get_dst_name(char *path){
    char *token;
    char *previous_token = path;
    // make a copy before find the destination since strtok modify the string
    char *rest = strdup(path);
    while((token = strtok_r(rest, "/", &rest)) != NULL){
        previous_token = token;
    }
    return previous_token;
}

/**
 * traverse the path until reaches the destination
 * return the inode index of the *parent* directory of the dst
*/
int get_parent_dir_inode_index(char *path, char *dst){

    char *token;
    // make a copy before traversing
    char *rest = strdup(path);

    // start traverse at the root
    int inode_index = 1;
    int parent_inode_index;;

    while((token = strtok_r(rest, "/", &rest)) != NULL){

        // update the parent inode index
        parent_inode_index = inode_index;
        if(strcmp(dst, token) == 0){
            return parent_inode_index;
        }

        // get the inode index of the matching file/directory
        inode_index = get_matching_file(inode_index, token);

        // the path is invalid or the end of path is reaches
        if(!inode_index){
            exit(-ENOENT);
        }
    }
    // handle case when the path is just the root /
    return inode_index;
}

/**
 * initialize a new directory with appropriate information
 */
void initialize_dir_entry(unsigned char *position, unsigned int inode, unsigned short rec_len, unsigned char name_len, unsigned char file_type, char *name){
    struct ext2_dir_entry *dir = (struct ext2_dir_entry *)(position);

    dir->inode = inode;
    dir->rec_len = rec_len;
    dir->name_len = name_len;
    dir->file_type = file_type;
    // copy the non null terminated name
    strncpy(dir->name, name, strlen(name));
}


/**
 * write the directory entry at the provided position
*/
void create_new_directory(unsigned char *pos, unsigned int inode_num, unsigned int parent_inode, unsigned short rec_len, int name_len, unsigned char file_type, char *name){
    
    // bookkeeping new directory information
    initialize_dir_entry(pos, inode_num, rec_len, (char)name_len, file_type, name);

    // finish creating new directory if the type is not EXT2_FT_DIR
    if(file_type != EXT2_FT_DIR){
        return;
    }
    struct ext2_inode *inode = &inode_table[inode_num - 1];

    // create a new datablock to store the local and parent directory
    unsigned int nxt_data_block = make_nxt_data_block_valid();
    inode->i_block[0] = nxt_data_block;

    unsigned char *position = (unsigned char *)(disk + EXT2_BLOCK_SIZE * nxt_data_block);

    // add the local directory inside this new directory
    initialize_dir_entry(position, inode_num, 12, 1, EXT2_FT_DIR, ".");

    // add parent directory to the new directory
    initialize_dir_entry((unsigned char *)(position + 12), parent_inode, 1012, 2, EXT2_FT_DIR, "..");
}

/**
 * add a new directory to the parent under inode number: parent_in
 * the directory contains information: name, nxt_inode_num, and file type
 *
*/
void add_directory_to_parent(unsigned int parent_in, char *name, int nxt_inode_num, unsigned char file_type){
    // TODO: handle case all blocks are invalid Maybe be solved
    unsigned short rec_size;
    struct ext2_dir_entry *dir_entry;
    unsigned int shrinked_size;
    unsigned int space_left;
    unsigned int nxt_data_block;
    unsigned int block_num;
    unsigned char *write_location;

	// changes
    struct ext2_inode *parent_inode = &inode_table[parent_in - 1];

    int allocate_new_blocks = 0;

    // get the last data block of the parent directory
    int index = parent_inode->i_blocks / 2;

    // check if the parent directory has any allocated data blocks
    if(index == 0){
        allocate_new_blocks = 1;
    }

    if(!allocate_new_blocks){
        index--;

        // get the data block number at that slot
        block_num = parent_inode->i_block[index];

        // make the new directory record size at 4 boundary
        rec_size = make_four_byte_boundary(MIN_RECORD_SIZE + strlen(name));

        // start inserts the directory record at the last block if there are space
  		unsigned char *start = (unsigned char *)(disk + EXT2_BLOCK_SIZE * block_num);
  		int byte_index = 0;
        // find the last directory entry at the last block
  		do{
  			dir_entry = (struct ext2_dir_entry *)(start + byte_index);
  			byte_index += dir_entry->rec_len;
  		}while(byte_index < EXT2_BLOCK_SIZE);

        // get the shrinked size of the last directory in the block
        shrinked_size = make_four_byte_boundary(dir_entry->name_len + sizeof(struct ext2_dir_entry));

        // get the rec_size of the new directory, this size should be bounded by four since shrinked_size is and dir_entry->rec_len also
        space_left = dir_entry->rec_len - shrinked_size;
        if (space_left >= rec_size){
            // update the previous directory size
            dir_entry->rec_len = shrinked_size;
			int name_len = strlen(name);

            int previous_dir_offset = byte_index - space_left;
            create_new_directory((unsigned char *)(start + previous_dir_offset), nxt_inode_num, parent_in, space_left, name_len, file_type, name);
            return;
		}
		// case where there are free direct blocks left
		else if(index + 1 < DIRECT_BLOCK_ENTRIES){
            allocate_new_blocks = 1;
        }
    }

    // either the last block does not have enough space or the parent directory does not allocated data blocks
    if(allocate_new_blocks){
        // allocate a new data block for the new directory inside the parent directory
        nxt_data_block = make_nxt_data_block_valid();
        // get the disk location that need to be written with the new dir entry
        write_location = (unsigned char *)(disk + EXT2_BLOCK_SIZE * nxt_data_block);
        // write the directory entry at that data block
        int name_len = strlen(name);
        create_new_directory(write_location, nxt_inode_num, parent_in, EXT2_BLOCK_SIZE, name_len, file_type, name);

        // bookkeeping the parent directory of the new directory
        
        // update the size information
        parent_inode->i_blocks += 2;
        parent_inode->i_size += EXT2_BLOCK_SIZE;
    }else{
        // no space error
        exit(-ENOSPC);
    }
    return;
}

/**
 * this function is called whenever a new inode is created
 * inode_num : the inode number
*/
void init_new_inode(int inode_num, unsigned short i_mode){
    struct ext2_inode *inode = &inode_table[inode_num - 1];
    inode->i_mode = i_mode;
    inode->i_uid = 0;
    inode->i_size = 0;
    inode->i_links_count = 1;
    inode->i_blocks = 0;
    inode->i_dtime = 0;
    inode->i_gid = 0;
}

/**
 * check the file_name at the db_block
 * assume the db_block is valid
 *
 * return the index of the inode
 */
int check_dir_record_at(unsigned int db_block ,char *file_name){

    unsigned char *current_position = (unsigned char *)(disk + EXT2_BLOCK_SIZE * db_block);
    int byte_index = 0;

    while(byte_index < EXT2_BLOCK_SIZE){
        struct ext2_dir_entry *dir = (struct ext2_dir_entry *)(current_position + byte_index);

        // get the name of the current directory entry
        char *name = malloc(sizeof(char) * (dir->name_len + 1));
        get_null_terminated_name(&name, dir->name, dir->name_len);

        // check for the content of the dir_entry and see if it matches the file_name string
        int same = strcmp(name, file_name);
        free(name);
        if (same != 0){
			byte_index += dir->rec_len;
            continue;
        }
        // return the index to the inode table
        return dir->inode - 1;
    }
    // the file_name is not inside this db_block
    return 0;
}

/**
 * return the inode index in the inode table correspond to the file (given file_name)
 * return 0 if no matching
 *
 * if the flag indirect_block is set ==> also look at the indirect blocks for file_name
 * otherwise, just the direct blocks
*/
int get_matching_file(unsigned int inode_table_index, char *file_name){
    struct ext2_inode *inode = &inode_table[inode_table_index];

    // traverse each data block in the inode struct
    for(int i = 0; i < inode->i_blocks / 2; i++){
        int result;
        if((result = check_dir_record_at(inode->i_block[i], file_name)) > 0){
            return result;
        }
    }

    return 0;
}

/**
 * copy the buffer into the block_index of the inode at inode_index of the inode_table
*/
void copy_data_to_dst(int data_size, char *buffer, int inode_index, int block_index){

	struct ext2_inode *inode = &inode_table[inode_index];
    // default to direct data blocks
    unsigned int *db_array = inode->i_block;

    // when the file is big enough to extends to a single indirect block
    if(block_index == DIRECT_BLOCK_ENTRIES){
        unsigned int indirect_db = make_nxt_data_block_valid();
        inode->i_block[DIRECT_BLOCK_ENTRIES] = indirect_db;
        db_array = (unsigned int *)(disk + EXT2_BLOCK_SIZE * indirect_db);
        // account for the size of the indirect block
        inode->i_blocks += 2;
    }

    // case where need the indirect block index ==> we need to modify the block index so that
    // it points to the indirect array instead
    if(block_index >= DIRECT_BLOCK_ENTRIES){
        db_array = (unsigned int *)(disk + EXT2_BLOCK_SIZE * inode->i_block[12]);
        // get the correct index inside the indirect block array
        block_index -= DIRECT_BLOCK_ENTRIES;

        // indicate that even the indirect block block does not have enough space
        if(block_index >= EXT2_BLOCK_SIZE / 4){
            exit(-ENOSPC);
        }
    }
    
    // create a new data block to store new data
    unsigned int nxt_bn = make_nxt_data_block_valid();
    db_array[block_index] = nxt_bn;

    // write to the specified location on disk
    char *write_position = (char *)(disk + nxt_bn * EXT2_BLOCK_SIZE);
    strncpy(write_position, buffer, data_size);

    // bookkeeping for the inode file size and number of disk_block it occupies
    inode->i_size += data_size;
    inode->i_blocks += 2;
}

/**
 * map inode.i_mode to directory file type
*/
unsigned char map_inode_file_type(unsigned short mode){
    if((mode >> 12) == (EXT2_S_IFREG >> 12)){
        return EXT2_FT_REG_FILE;
    }
    if((mode >> 12) == (EXT2_S_IFDIR >> 12)){
        return EXT2_FT_DIR;
    }
    if((mode >> 12) == (EXT2_S_IFDIR >> 12)){
        return EXT2_FT_SYMLINK;
    }
    return EXT2_FT_UNKNOWN;
}