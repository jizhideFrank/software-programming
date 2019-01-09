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

int fd;
int total_fixes = 0;

void parse_arguments(int argc, char **argv){
    if(argc != 2){
        fprintf(stderr, "Usage: %s <image file name>\n", argv[0]);
        exit(-EINVAL);
    }
    fd = open(argv[1], O_RDWR);
}

/**
 * helper function for block_count_inconsistent_checker
 * */
int count_free_positions(unsigned char *bitmap, int total){
    int result = 0;
    for (int i = 0; i < total; i++) {
        unsigned char byte = bitmap[i];
        for (int j = 0; j <= 7; j++){
            if (is_free_bit(byte, j)){
                result ++;
            }
        }
    }
    return result;
}

/**
 * helper function for block_count_inconsistent_checker
 * */
void print_block_counts_msg(char *data_structure, char *type, int off){
    printf("%s's free %s counter was off by %d compared to the bitmap\n", data_structure, type, off);
}

/**
 * check inconsistancy between number of free inodes/blocks and the counters
*/
void bitmap_counters_consistent_checker(){
    int delta, free_inodes, free_db_blocks;
    free_inodes = count_free_positions(inode_block_bitmap, sb->s_inodes_count / 8);
    free_db_blocks = count_free_positions(data_block_bitmap, sb->s_blocks_count / 8);

    // by assumption, we trust the bitmap
    int sb_free_inodes = sb->s_free_inodes_count;
    int sb_free_db_blocks = sb->s_free_blocks_count;

    // check inconsistancy for Super blocks

    if(sb_free_inodes != free_inodes){
        // update inodes counter and bookkeepings
        sb->s_free_inodes_count = free_inodes;
        delta = abs(free_inodes - sb_free_inodes);
        total_fixes += delta;
        print_block_counts_msg("superblocks", "inodes", delta);
    }
    
    if(sb_free_db_blocks != free_db_blocks){
        // update data block counter and bookkeepings
        sb->s_blocks_count = free_db_blocks;
        delta = abs(free_db_blocks - sb_free_db_blocks);
        total_fixes += delta;
        print_block_counts_msg("superblocks", "blocks", delta);
    }
    // check inconsistancy for Block group
    int bg_free_inodes_count = gb->bg_free_inodes_count;
    int bg_free_blocks_count = gb->bg_free_blocks_count;

    if(bg_free_inodes_count != free_inodes){
        // update inodes counter and bookkeepings
        gb->bg_free_inodes_count = free_inodes;
        delta = abs(free_inodes - bg_free_inodes_count);
        total_fixes += delta;
        print_block_counts_msg("block group", "inodes", delta);
    }
    
    if(bg_free_blocks_count != free_db_blocks){
        // update data block counter and bookkeepings
        gb->bg_free_inodes_count = free_db_blocks;
        delta = abs(free_db_blocks - bg_free_blocks_count);
        total_fixes += delta;
        print_block_counts_msg("block group", "blocks", delta);
    }
}

/**
 * check if the datablock with db_num consistent with the bitmap
*/
void check_db_consistent(int db_num, int *db_inconsistent){
    if(!valid_data_block_entry(db_num)){
        set_in_bitmap(db_num, data_block_bitmap);
        (*db_inconsistent) ++;
        total_fixes ++;
    }
}

/**
 * check the file_type consistancy in a depth-first manner starting from the root
 * 
 * assume the inode_table[inode_num - 1] points to a directory inode
 * 
 * the input inode_num is *not* index
*/
void recursive_checker(int inode_num, int traverse){

    // get the inode that need to be traversed
    struct ext2_inode *inode = &inode_table[inode_num - 1];
    int inconsistent_dbs = 0;

    int bound = inode->i_blocks / 2;
    if(bound > DIRECT_BLOCK_ENTRIES){
        bound--;
    }

    // assume only need to traverse direct blocks
    for (int i = 0; i < bound; i++){

        int db_num;
        // consider the case of indirect blocks
        if(i >= DIRECT_BLOCK_ENTRIES){
            unsigned int indirect_db = inode->i_block[DIRECT_BLOCK_ENTRIES];
            unsigned int *indirect_db_array = (unsigned int *)(disk + indirect_db * EXT2_BLOCK_SIZE);

            if(i == DIRECT_BLOCK_ENTRIES){
                // check for indirect datablock inconsisiency
                check_db_consistent(indirect_db, &inconsistent_dbs);
            }

            int indirect_index = i - DIRECT_BLOCK_ENTRIES;
            db_num = indirect_db_array[indirect_index];
        }else{
            db_num = inode->i_block[i];
        }

        // common operation for direct datablocks and indirect datablocks
        // accumulate count of inconsistentcy between datablock bitmap and data blocks
        check_db_consistent(db_num, &inconsistent_dbs);

        // this is used to handle case of "lost+found"
        if(!traverse){
            continue;
        }

        // not goes through directory entry in the indirect data blocks
        if(i >= DIRECT_BLOCK_ENTRIES){
            continue;
        }

        unsigned char *start_position = (unsigned char *)(disk + EXT2_BLOCK_SIZE * db_num);
        int byte_index = 0;
        while(byte_index < EXT2_BLOCK_SIZE){
            // get the directory entry and its corresponding inode
            struct ext2_dir_entry *dir = (struct ext2_dir_entry *)(start_position + byte_index);
            struct ext2_inode *inode = &inode_table[dir->inode - 1];

            // found inconsistency of file type between dir entry and inode
            unsigned char inode_file_type = map_inode_file_type(inode->i_mode);
            if(dir->file_type != inode_file_type){
                // fix the dir's file type
                dir->file_type = inode_file_type;
                total_fixes ++;
                printf("Fixed: Entry type vs inode mismatch: inode [%d]\n", dir->inode);
            }

            // update inode bitmap to make it consistent
            if(!valid_inode_entry(dir->inode)){
                set_in_bitmap(dir->inode, inode_block_bitmap);
                total_fixes ++;
                printf("Fixed: inode [%d] not marked as in-use\n", dir->inode);
            }

            // i_dtime should  be zero
            if(inode->i_dtime){
                inode->i_dtime = 0;
                total_fixes ++;
                printf("Fixed: valid inode marked for deletion: [%d]\n", dir->inode);
            }
            
            // when the dir entry is a nondirectory entry, just make sure the data blocks are consistent with bitmap
            if((inode->i_mode & EXT2_S_IFDIR) == 0){
                int inconsistent_files = 0;

                for(int j = 0; j < inode->i_blocks / 2; j++){
                    int file_db = inode->i_block[j];
                    check_db_consistent(file_db, &inconsistent_files);
                }

                if (inconsistent_files > 0){
                    printf("Fixed: %d in-use data blocks not marked in data bitmap for inode: [%d]\n", inconsistent_files, dir->inode);
                }
            }

            int keep_traverse = 1;
            if(strcmp("lost+found", dir->name) == 0){
                keep_traverse = 0;
            }

            // recursively if it is a directory and it is not parent and local
            if(inode->i_mode & EXT2_S_IFDIR && (strcmp(dir->name, ".") != 0) && (strcmp(dir->name, "..") != 0)){
                recursive_checker(dir->inode, keep_traverse);
            }
            byte_index += dir->rec_len;
        }
    }
    if(inconsistent_dbs > 0){
        printf("Fixed: %d in-use data blocks not marked in data bitmap for inode: [%d]\n", inconsistent_dbs, inode_num);
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
    
    // handle part a
    bitmap_counters_consistent_checker();

    // handle part b, c, d, e
    recursive_checker(2, 1);

    // print msg amount the total amount of fixes
    if(total_fixes > 0){
        printf("%d file system inconsistencies repaired!\n", total_fixes);
    }else{
        printf("No file system inconsistencies detected!\n");
    }
}
