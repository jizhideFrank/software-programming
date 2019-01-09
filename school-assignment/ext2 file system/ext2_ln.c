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

char *src_path, *dst_path;
int fd;
int is_symlink = 0;

void parse_arguments(int argc, char **argv){

    if(argc < 4){
        fprintf(stderr, "Usage: %s <image file name> <path to source file> <path to dest>\n", argv[0]);
        exit(-EINVAL);
    }
    if(argc > 5 || (argc > 5 && strcmp(argv[2], "-s") != 0)){
        fprintf(stderr, "Usage: %s <image file name> -s <path to source file> <path to dest>\n", argv[0]);
        exit(-EINVAL);
    }
    
    if(argc == 5){
        is_symlink = 1;
        is_absolute_path(argv[3]);
        is_absolute_path(argv[4]);
        src_path = strdup(argv[3]); // the file that need to be pointed
        dst_path = strdup(argv[4]); // the simlink
    }else{
        is_absolute_path(argv[2]);
        is_absolute_path(argv[3]);
        src_path = strdup(argv[2]); // the file that need to be fointed
        dst_path = strdup(argv[3]); // the hardlink
    }
    fd = open(argv[1], O_RDWR);
}

int main(int argc, char **argv) {
    
    parse_arguments(argc, argv);

    // initialize all the datastructures before proceeding
    get_disk_image(fd);
    data_block_bitmap = get_block_bitmap();
    inode_block_bitmap = get_inode_bitmap();
    sb = get_super_block();
    gb = get_block_descriptor_table();
    inode_table = get_inode_table();

    // get the inode index of the link parent directory
    char *link_name = get_dst_name(dst_path);
    unsigned int link_parent = get_parent_dir_inode_index(dst_path, link_name);
    // check for existance of link name in the parent directory including the indirect blocks
    if (get_matching_file(link_parent, link_name)){
        exit(-EEXIST);
    }

    // get inode index parent directory of the source file
    char *file_name = get_dst_name(src_path);
    unsigned int file_parent = get_parent_dir_inode_index(src_path, file_name);
    // get the inode index of the source file that **need to be linked**
    int dst_ii = get_matching_file(file_parent, file_name);
    // the source file does not exist in the src_path
    if(!dst_ii){
        exit(-ENOENT);
    }

    // when try to point the hard link to a directory
    if (!is_symlink && INODE_IS_DIR(inode_table[dst_ii].i_mode)){
        exit(-EISDIR);
    }

    int inode_num = dst_ii + 1;
    // inode number and the file type of the hardlink
    unsigned char file_type = map_inode_file_type(inode_table[dst_ii].i_mode);

    // allocate a inode for the symlink and copy the path into its data block
    if(is_symlink){

        // create a inode for the is_symlink and populate the datablock with the path
        inode_num = make_nxt_inode_valid();
        init_new_inode(inode_num, EXT2_S_IFLNK);

        // copy the path string into the symlink_inode's data blocks
	    int path_length = strlen(src_path);
        // assume we only need one block for the symlink, said by: https://piazza.com/class/jlrdrboeft389?cid=710
        copy_data_to_dst(path_length, src_path, inode_num - 1, 0);

        // inode number and file type for the symlink
        file_type = EXT2_FT_SYMLINK;
    }

    // add the directory entry for the link under its parent entry
    add_directory_to_parent(link_parent + 1, link_name, inode_num, file_type);

    // update link count of the pointed inode if not is_symlink
    if(!is_symlink){
        inode_table[dst_ii].i_links_count += 1;
    }
    return 0;
}