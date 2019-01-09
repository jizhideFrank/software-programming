#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>
#include "ext2_utils.h"
#include <time.h>

char *path;
int fd;

void parse_arguments(int argc, char **argv){
    if(argc != 3) {
        fprintf(stderr, "Usage: %s <image file name> <path to link>\n", argv[0]);
        exit(-EINVAL);
    }
    path = strdup(argv[2]);
    // get the image file provided
    fd = open(argv[1], O_RDWR);
}


/**
 * remove the delete_file from the db_block
 * db_block is the data block that need to be traversed
 * 
 * exit(0) if success, otherwise finishing traversing the whole db_block
*/
void remove_file_at_block(unsigned int db_block ,char *delete_file){
    
	unsigned char *current_position;
    struct ext2_dir_entry *dir;
	
    // flag to indicate when to reset inode number (corner case)
    int delete_first_entry = 1;

    // traverse the datablock to find the matching delete file name
	current_position = (unsigned char *)(disk + EXT2_BLOCK_SIZE * db_block);
	struct ext2_dir_entry *previous_dir = (struct ext2_dir_entry *)current_position;
	int byte_index = 0;

    // traverse each directory entry at a time
	while(byte_index < EXT2_BLOCK_SIZE){
		dir = (struct ext2_dir_entry *)(current_position + byte_index);

        // get the name of the current directory entry
        char *name = malloc(sizeof(char) * (dir->name_len + 1));
        get_null_terminated_name(&name, dir->name, dir->name_len);
        
        int same = strcmp(name, delete_file);
        free(name);
        // not the directory entry we are looking for ==> skip this loop
        if (same != 0){
            delete_first_entry = 0;
            previous_dir = dir;
			byte_index += dir->rec_len;
            continue;
        }
        
        // at this stage, we have found corresponding dir entry of the delete file

        // get the corresponding inode
        struct ext2_inode *df_inode = &inode_table[dir->inode - 1];
		
		// multiple names point to the same inode
        df_inode->i_links_count--;
        if(df_inode->i_links_count >= 1){
            exit(-0);
        }

        // reset the inode of the deleted file in inode bitmap
        reset_in_bitmap(dir->inode, inode_block_bitmap);

        int bound = df_inode->i_blocks / 2;
        if(bound > DIRECT_BLOCK_ENTRIES){
            bound--;
        }

        // reset the datablocks inside the datablock bitmap
        for(int j = 0; j < bound; j++){

            int db_num;
            if(j >= DIRECT_BLOCK_ENTRIES){
                // get the indirect data block array (contains a array of datablock pointers)
                unsigned int *indirect_blocks;
                get_indirect_blocks(dir->inode - 1, &indirect_blocks);
                // get the data block pointer inside the indirect data block
                db_num = indirect_blocks[j - DIRECT_BLOCK_ENTRIES];
            }else{
                db_num = df_inode->i_block[j];
            }
            reset_in_bitmap(db_num, data_block_bitmap);
        }

        //TODO: check the equal sign 
        // also reset the indirect_bn if necessary
        if(bound > DIRECT_BLOCK_ENTRIES){
            reset_in_bitmap(df_inode->i_block[DIRECT_BLOCK_ENTRIES], data_block_bitmap);
        }

        // corner case: if the entry is the first entry of the block
        if(delete_first_entry){
            dir->inode = 0;
        }
		// otherwise just extends the record length of the previous dir entry
		else{
            previous_dir->rec_len += dir->rec_len;
        }

        // reset necessary information for the inode of the delete_file
        df_inode->i_dtime = time(NULL);

        exit(-0);
	}
}


int main(int argc, char **argv){

    parse_arguments(argc, argv);
    // make sure absolute path and trailing slash does not exist
    is_absolute_path(path);

    // initialize all the datastructures before proceeding
    get_disk_image(fd);
    data_block_bitmap = get_block_bitmap();
    inode_block_bitmap = get_inode_bitmap();
    sb = get_super_block();
    gb = get_block_descriptor_table();
    inode_table = get_inode_table();

    // get the name of the file that need to be deleted
    char *delete_file = get_dst_name(path);
    // get the parent's inode index
    int parent_ii = get_parent_dir_inode_index(path, delete_file);
    // get the delete file's inode index, including traverse the indirect blocks
    int delete_file_ii = get_matching_file(parent_ii, delete_file);

    // try to remove a file that does not exist
    if(!delete_file_ii){
        exit(-ENOENT);
    }

    // when try to delete a existing directory
    if(INODE_IS_DIR(inode_table[delete_file_ii].i_mode)){
        exit(-EISDIR);
    }

    // get the inode the of parent directory of the delete file
    struct ext2_inode *parent_inode = &inode_table[parent_ii];

    for(int j = 0; j < parent_inode->i_blocks / 2; j++){
        
        int db_num = parent_inode->i_block[j];
        // remove files that are on the indirect data blocks
        if(j >= DIRECT_BLOCK_ENTRIES){
            unsigned int *indirect_blocks;
            get_indirect_blocks(parent_ii, &indirect_blocks);
            db_num = indirect_blocks[j - DIRECT_BLOCK_ENTRIES];
        }
        // try to remove file that are block db_num if it exists
        remove_file_at_block(db_num, delete_file);
    }
}
