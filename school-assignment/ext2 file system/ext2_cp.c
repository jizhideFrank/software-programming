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

// TODO: handle case where the native file size is too big

// TODO: handle case where the src path is invalid

// TODO: handle case where the destination is a custom name (then need to create a file and copy the content from source into it)

// TODO: handle case where the final destination is file, in which case override the contents, leave the file name the same

// TODO: in case of symbolic link from source, cpy whatever contents leads by symlink to the final destination
// above also analogus when destination is symlink

//TODO: in case both ends are symbolic links, copy whatever contents leaded by one path to the location lead by the destination symlink
char *src_path, *dst_path;
int fd;

void parse_arguments(int argc, char **argv){
    if(argc != 4){
        fprintf(stderr, "Usage: %s <image file name> <path to source file> <path to dest>\n", argv[0]);
        exit(-EINVAL);
    }

    is_absolute_path(argv[3]);

    src_path = strdup(argv[2]);
    dst_path = strdup(argv[3]);

    fd = open(argv[1], O_RDWR);
}


/**
 * copy the file from src to data blocks of destination inode
*/
void copy_file_to_dst(FILE *fd, int inode_index){

    int bytes_read;
    int block_index = 0;
	char *buffer = malloc(sizeof(char) * (EXT2_BLOCK_SIZE + 1));

    // keep writing data to inode's data block if there are any
    while((bytes_read = fread(buffer, sizeof(char), EXT2_BLOCK_SIZE, fd)) > 0){
        copy_data_to_dst(bytes_read, buffer, inode_index, block_index++);
        free(buffer);
        buffer = malloc(sizeof(char) * (EXT2_BLOCK_SIZE + 1));
    }
    free(buffer);
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

    FILE *copy_fd;
    if((copy_fd = fopen(src_path, "r")) == NULL){
        // check if the source file exist
        exit(-ENOENT);
    }

    // TODO: check directory at the end of the src path using stat()
    struct stat file_stat;
    if(stat(src_path, &file_stat) < 0){
        perror("stat sys call error");
        exit(-EINVAL);
    }

    // when the file is not symlink and not regular files
    if (!S_ISREG(file_stat.st_mode) && !S_ISLNK(file_stat.st_mode)){
        exit(-EINVAL);
    }

    // get the destination name from the path
    char *dst_name = get_dst_name(dst_path);

    // create a new file with name the same as source if the user does not provide a custom name
    if (strcmp(strrchr(dst_path, '/'), "/") == 0){
        dst_name = get_dst_name(src_path);
    }

    // get he parent directory 's inode of the destination
    unsigned int dst_parent_ii = get_parent_dir_inode_index(dst_path, dst_name);

    // check existance of the dst_name in the parent directory, return error if necessary
    unsigned int matching_file = get_matching_file(dst_parent_ii, dst_name);
    if (matching_file){
        exit(-EEXIST);
    }

    // create a inode for this new file
    unsigned int inode_num = make_nxt_inode_valid();
    init_new_inode(inode_num, EXT2_S_IFREG);

    // add a new directory entry under the parent directory to indicate new file exists
    add_directory_to_parent(dst_parent_ii + 1, dst_name, inode_num, EXT2_FT_REG_FILE);

    // copy the content of file (copy_fd) to datablocks of inode
    copy_file_to_dst(copy_fd, inode_num - 1);

    fclose(copy_fd);
    return 0;
}
