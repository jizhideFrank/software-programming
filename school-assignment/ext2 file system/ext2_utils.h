#include "ext2.h"

// additional constants about ext2 file system
#define MIN_RECORD_SIZE sizeof(int) + sizeof(short) + 2
#define DIRECTORY_SIZE_BOUNDARY 4
#define TOTAL_INDIRECT_BLOCK_ENTRIES EXT2_BLOCK_SIZE / sizeof(unsigned int)
#define DIRECT_BLOCK_ENTRIES 12
#define DISK_SECTOR_SIZE 512
#define TOTAL_DATA_BLOCKS 128
#define TOTAL_INODES 32

#define MIN(a,b)((a < b) ? a : b)
#define INODE_IS_DIR(a)(a & EXT2_S_IFDIR)
#define DIR_IS_SYM(a)(a & EXT2_FT_SYMLINK)
#define DIR_IS_REG(a)(a & EXT2_FT_REG_FILE)

unsigned char *disk;
unsigned char *data_block_bitmap;
unsigned char *inode_block_bitmap;
struct ext2_super_block *sb;
struct ext2_group_desc *gb;
struct ext2_inode *inode_table;

// helper function to get the datastructre in the file system
void get_disk_image(int fd);
struct ext2_super_block *get_super_block();
struct ext2_group_desc *get_block_descriptor_table();
struct ext2_inode *get_inode_table();
unsigned char *get_block_bitmap();
unsigned char *get_inode_bitmap();


//
void init_new_inode(int inode_num, unsigned short i_mode);
void initialize_dir_entry(unsigned char *position, unsigned int inode, unsigned short rec_len, unsigned char name_len, unsigned char file_type, char *name);
unsigned char map_inode_file_type(unsigned short mode);
int is_free_bit(unsigned char byte, int pos);
int valid_data_block_entry(unsigned int block_num);
int valid_inode_entry(unsigned int inode_num);
void is_absolute_path(char *path);
void get_indirect_blocks(int inode_ii, unsigned int **indirect_blocks);
void reset_in_bitmap(unsigned int block_num, unsigned char *bitmap);
void set_in_bitmap(unsigned int block_num, unsigned char *bitmap);
void blocks_positions(unsigned char **starting, unsigned char **ending, unsigned int block_num);
void get_null_terminated_name(char **null_terminate_name, char *name, int name_length);
int check_free_bit_from_byte(unsigned char byte);
unsigned int make_nxt_data_block_valid();
unsigned int make_nxt_inode_valid();
int make_four_byte_boundary(int current);
void create_new_directory(unsigned char *pos, unsigned int inode_num, unsigned int parent_inode, unsigned short rec_len, int name_len, unsigned char file_type, char *name);
int last_block_in_dir(struct ext2_inode *parent_inode);
char *get_dst_name(char *path);
int get_parent_dir_inode_index(char *path, char *dst);
void add_directory_to_parent(unsigned int parent_in, char *name, int nxt_inode_num, unsigned char file_type);
int check_dir_record_at(unsigned int db_block ,char *file_name);
int get_matching_file(unsigned int inode_table_index, char *file_name);
int writes_to_blocks(unsigned int *db_array, unsigned int num_entries, int bytes_read, struct ext2_inode *inode, char *buffer);
void copy_data_to_dst(int data_size, char *buffer, int inode_index, int block_index);
