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
char *path;

/*
 * parse the arguments from user and return error if necessary
 * otherwise return a file descriptor
 * */
void parse_arguments(int argc, char **argv){
    if(argc != 3) {
        fprintf(stderr, "Usage: %s <image file name> <path>\n", argv[0]);
        exit(-EINVAL);
    }
    path = strdup(argv[2]);
    // get the image file provided
    fd = open(argv[1], O_RDWR);
}

int main(int argc, char **argv) {
    parse_arguments(argc, argv);

    // make sure absolute path and trailing slash does not exist
    is_absolute_path(path);

    // 128 blocks inside the disk each block of 1024 bytes of memory size
    disk = mmap(NULL, 128 * 1024, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if(disk == MAP_FAILED) {
        perror("mmap");
        exit(-1);
    }

    // initialize all the datastructures before proceeding
    get_disk_image(fd);
    data_block_bitmap = get_block_bitmap();
    inode_block_bitmap = get_inode_bitmap();
    sb = get_super_block();
    gb = get_block_descriptor_table();
    inode_table = get_inode_table();

    // extract the new directory name
    char *new_directory = get_dst_name(path);
    if(strlen(new_directory) > EXT2_NAME_LEN){
        exit(-ENAMETOOLONG);
    }

    // get the parent's inode index
    int parent_ii = get_parent_dir_inode_index(path, new_directory);
    // varify the existance of the new_directory
    int existence = get_matching_file(parent_ii, new_directory);

    if (!existence){
        // create a inode for this new directory
        int nxt_inode_num = make_nxt_inode_valid();
        init_new_inode(nxt_inode_num, EXT2_S_IFDIR);

        // bookkeeping necessary information for the new directory
        struct ext2_inode *inode = &inode_table[nxt_inode_num - 1];
        inode->i_blocks += 2;
        inode->i_links_count += 1;
        inode->i_size += EXT2_BLOCK_SIZE;

        // for the .. link count
        struct ext2_inode *parent = &inode_table[parent_ii];
        parent->i_links_count++;

        add_directory_to_parent(parent_ii+1, new_directory, nxt_inode_num, EXT2_FT_DIR);
    }else{
        exit(-EEXIST);
    }
    // bookkeeping directory informaiton in block group descriptor table
    gb->bg_used_dirs_count++;
    return 0;
}
