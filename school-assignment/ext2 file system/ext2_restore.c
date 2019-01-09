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

void adjust_dir_rec_len(unsigned char *current_gap_pos, int recovered_gap_pos,  int recovered_gap_size, unsigned char *matching_gap_address){
    int byte_i = 0;
    struct ext2_dir_entry *dir;
    // adjust the rec_len of the "gaps" inside the dir
    while(byte_i < recovered_gap_pos){

        unsigned char *gap_location = (unsigned char *)(current_gap_pos + byte_i);
        dir = (struct ext2_dir_entry *)(gap_location);
        // adjust the rec_len

        //TODO: note the ordering of delete determine this
        if(((unsigned char *)(gap_location + dir->rec_len)) > matching_gap_address){
            dir->rec_len -= recovered_gap_size;
        }

        int actual_size = make_four_byte_boundary(dir->name_len + sizeof(struct ext2_dir_entry));
        byte_i += actual_size;
    }
}

/**
 * look for the gap inside the data block(db_num)
 * and try to find gap that has a dir->name = name
 *
 * previous_dir keeps track of the previous directory record of the returned gap in case failed to restore
 *
 * return the gap entry if found
 * return null if not found
*/
struct ext2_dir_entry *find_the_match_gap(unsigned int db_num, char *file_name, unsigned char **previous_dir, unsigned char **match_gap_pos, int *returned_gap_offset){

    unsigned char *current_position = (unsigned char *)(disk + EXT2_BLOCK_SIZE * db_num);
	int byte_index = 0;

    // traverse the datablock to find the matching delete file name
    struct ext2_dir_entry *dir, *gap;
    while(byte_index < EXT2_BLOCK_SIZE){
        dir = (struct ext2_dir_entry *)(current_position + byte_index);
        *previous_dir = (unsigned char *)(current_position + byte_index);

        // get the actual size of the directory entry in 4 bytes boundary
        int actual_len = make_four_byte_boundary(dir->name_len + sizeof(struct ext2_dir_entry));
        int gap_space = dir->rec_len - actual_len;
        // no "gap" in this entry or the gap is too small
        if(gap_space < sizeof(struct ext2_dir_entry)){
            byte_index += dir->rec_len;
            continue;
        }

        // TODO: there can be multiple gaps are combined and remove the second one in the gap before the first one
        unsigned char *current_gap_pos = (unsigned char *)(current_position + byte_index + actual_len);
        int gap_byte_i = 0;

        // relative to the previous directory
        (*returned_gap_offset) = actual_len;

        // handle nested "gaps"
        while(gap_byte_i < gap_space){
            
            // store the location of the matching gap
            *match_gap_pos = (unsigned char *)(current_gap_pos + gap_byte_i);
            gap = (struct ext2_dir_entry *)(current_gap_pos + gap_byte_i);

            // get the name
            char *name = malloc(sizeof(char) * (gap->name_len + 1));
            get_null_terminated_name(&name, gap->name, gap->name_len);

            // check if the name is matching
            int same = strcmp(name, file_name);
            free(name);
            // if it is the same, return the directory entry of the deleted gap
            if (same == 0){
                // check if user tries to restore directory
                if(gap->file_type & EXT2_FT_DIR){
                    exit(-EISDIR);
                }
                // cannot recover a file that is the first entry of the block
                if(gap->inode == 0 || valid_inode_entry(gap->inode)){
                    //*previous_dir = NULL;
                    exit(-ENOENT);
                }
                return gap;
            }

            int actual_gap_len =  make_four_byte_boundary(gap->name_len + sizeof(struct ext2_dir_entry));
            // when there is a nested gap
            gap_byte_i += actual_gap_len;
            (*returned_gap_offset) += actual_gap_len;
        }

		byte_index += dir->rec_len;
    }
    return NULL;
}

/**
 * confirm any reallocation of datablock inside the inode_num
 *
 * if all data blocks pointed are invalid ==> no reallocation since delete
 * if there exist a data block pointed are valid ==> reallocation by some other inode
 *
 * exit(-ENOENT) if reallocation occurs
 * else do nothing
 */
void confirm_db_reallocations(unsigned int inode_num){
    struct ext2_inode *inode = &inode_table[inode_num - 1];

    int bound = inode->i_blocks / 2;
    if(bound > DIRECT_BLOCK_ENTRIES){
        // check if the indirect data block is occupied
        if(valid_data_block_entry(inode->i_block[DIRECT_BLOCK_ENTRIES])){
            exit(-ENOENT);
        }
        bound--;
    }

    for(int i = 0; i < bound; i++){

        int db_num;
        // traverse on the indirect blocks
        if(i >= DIRECT_BLOCK_ENTRIES){
            unsigned int *indirect_blocks;
            get_indirect_blocks(inode_num - 1, &indirect_blocks);
            db_num = indirect_blocks[i - DIRECT_BLOCK_ENTRIES];
        }else{
            db_num = inode->i_block[i];
        }

        if(valid_data_block_entry(db_num)){
            exit(-ENOENT);
        }
    }
}

void restore_data_blocks_in_bitmap(int inode_num){

    struct ext2_inode *inode = &inode_table[inode_num - 1];

    // re-valid all the datablocks entry **in order** according to the i_size of the inode
    int bound = inode->i_blocks / 2;
    // restore the bit of the indirect data block if necessary
    if(bound > DIRECT_BLOCK_ENTRIES){
        set_in_bitmap(inode->i_block[DIRECT_BLOCK_ENTRIES], data_block_bitmap);
        bound--;
    }

    for(int j = 0; j < bound; j++){

        int db_num;
        // traverse on the indirect blocks
        if(j >= DIRECT_BLOCK_ENTRIES){
            unsigned int *indirect_blocks;
            get_indirect_blocks(inode_num - 1, &indirect_blocks);
            db_num = indirect_blocks[j - DIRECT_BLOCK_ENTRIES];
        }else{
            db_num = inode->i_block[j];
        }
        set_in_bitmap(db_num, data_block_bitmap);
    }
}

int main(int argc, char **argv){

    parse_arguments(argc, argv);

    // initialize all the datastructures before proceeding
    get_disk_image(fd);
    data_block_bitmap = get_block_bitmap();
    inode_block_bitmap = get_inode_bitmap();
    sb = get_super_block();
    gb = get_block_descriptor_table();
    inode_table = get_inode_table();


    // TODO: handle case where the last part of the path is a /u/ for example

    char *restore_file = get_dst_name(path);
    int parent_ii = get_parent_dir_inode_index(path, restore_file);
    // check if the try-to-restore file already exists (note): not go to indirect block to check dir entry
    int exist = get_matching_file(parent_ii, restore_file);
    // try-to-restore file already exist
    if(exist){
        exit(-EEXIST);
    }


    // traverse parent directory of the restore file
    struct ext2_inode *parent_dir = &inode_table[parent_ii];
    int bound = parent_dir->i_blocks / 2;
    // restore the bit of the indirect data block if necessary
    if(bound > DIRECT_BLOCK_ENTRIES){
        bound--;
    }
    for(int i = 0; i < bound; i++){

        unsigned int db_num;

        if(i >= DIRECT_BLOCK_ENTRIES){
            unsigned int *indirect_blocks;
            get_indirect_blocks(parent_ii, &indirect_blocks);
            db_num = indirect_blocks[i - DIRECT_BLOCK_ENTRIES];
        }else{
            db_num = parent_dir->i_block[i];
        }
        unsigned char *previous = NULL;
        unsigned char *gap_location;
        // find a gap that has a name "restore_file"
        struct ext2_dir_entry *gap;
        // the offset is relative to the "previous" dir varaible
        int gap_offset = 0;

        // no matching gap with name restore_file is found
        if((gap = find_the_match_gap(db_num, restore_file, &previous, &gap_location, &gap_offset)) == NULL){
            continue;
        }
        
        // check the usage of datablocks pointed by the "gap"
        confirm_db_reallocations(gap->inode);

        // adjust all the dir->rec_len between the previous dir up to the dir at position gap_offset
        adjust_dir_rec_len(previous, gap_offset, gap->rec_len, gap_location);

        // restore the previously deleted file
        restore_data_blocks_in_bitmap(gap->inode);
        // re-valid the inode number in the inode_table
        set_in_bitmap(gap->inode, inode_block_bitmap);
        // reset necessary inode's field to reflect the restored file, deletion time
        struct ext2_inode *inode = &inode_table[gap->inode - 1];
        inode->i_dtime = 0;
        inode->i_links_count = 1;

        return 0;
    }

    exit(-ENOENT);
}
