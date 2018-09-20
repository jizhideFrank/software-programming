#include <stdio.h>
// Add your other system includes here.
#include <stdlib.h>
#include <sys/stat.h>
#include "ptree.h"
#include <string.h>


// Defining the constants described in ptree.h
const unsigned int MAX_PATH_LENGTH = 1024;

// If TEST is defined (see the Makefile), will look in the tests 
// directory for PIDs, instead of /proc.
#ifdef TEST
    const char *PROC_ROOT = "tests";
#else
    const char *PROC_ROOT = "/proc";
#endif


/*
 * Creates a PTree rooted at the process pid.
 * The function returns 0 if the tree was created successfully 
 * and 1 if the tree could not be created or if at least
 * one PID was encountered that could not be found or was not an 
 * executing process.
 */
int generate_ptree(struct TreeNode **root, pid_t pid) {
    // Here's a way to generate a string representing the name of
    // a file to open. Note that it uses the PROC_ROOT variable.

    char procfile[MAX_PATH_LENGTH + 1];

    //exe file does not exist
    if (sprintf(procfile, "%s/%d/exe", PROC_ROOT, pid) < 0) {
        return 1;
    }
    struct stat stat_buf;
    //failed with symbolic link
    if (lstat(procfile, &stat_buf) != 0){
        return 1;
    }

    //create dynamic allocated space for root
    *root = malloc(sizeof(struct TreeNode));
    (*root)->pid = pid;
    //set root's sibling to NULL;
    (*root)->sibling = NULL;


    FILE *cmdline_file;
    char cmdline_name[MAX_PATH_LENGTH];


    //cmdline file doest not exist
    if (sprintf(procfile, "%s/%d/cmdline", PROC_ROOT, pid) < 0){
        (*root)->name = NULL;
        return 1;
    }

    //open cmdline file
    cmdline_file = fopen(procfile, "r");

    //fail to open cmdline file, set the name to NULL
    if (cmdline_file == NULL){
        (*root)->name = NULL;
   
    }
    //open the cmdline file successfully
    else{
        //if cmdline file is non-empty
        if (fscanf(cmdline_file, "%s", cmdline_name) == 1){
            int length = strlen(cmdline_name);
            char *file_name = malloc(sizeof(char) * (length+1));
            strcpy(file_name, cmdline_name);
            (*root)->name = file_name;
            fclose(cmdline_file);
            
        }
        //if cmdline file is empty
        else{
            (*root)->name = NULL;
            fclose(cmdline_file);
        }
    }

    FILE *child_file;
    int current_pid;
    


    //childen file does not exist
    if (sprintf(procfile, "%s/%d/task/%d/children", PROC_ROOT, pid, pid) < 0){
        (*root)->child = NULL;
        return 1;
    }

    child_file = fopen(procfile, "r");

    //failed to open children file
    if (child_file == NULL){
        (*root)->child = NULL;
        return 0; 
    }
    //open children file successfully
    else{
        //empty children file
        if (fscanf(child_file, "%d", &current_pid) != 1){
            (*root)->child = NULL;
            return fclose(child_file);
        }
        //non-empty children file
        else{
            struct TreeNode **current_node = &((*root)->child);
            int success = generate_ptree(current_node, current_pid);
            if (success != 0){
                return 1;
            }

            else{
                while (fscanf(child_file, "%d", &current_pid) == 1){
                    //connect the siblings
                    current_node = &((*current_node)->sibling);
                    int flag =  generate_ptree(current_node, current_pid);
                    if (flag != 0){
                        return 1;
                    }
                }
            }
            fclose(child_file);
        }   
    }
    return 0 ;
}


void helper(struct TreeNode *root, int current, int required){
    printf("%*s", current * 2, "");
    printf("%d: %s\n", root->pid, root->name);
    if (current < required){
        if (root->child != NULL){
            helper(root->child, current + 1, required);
        }
            
    }
    if (root->sibling != NULL){
            helper(root->sibling, current, required);
    }
}


/*
 * Prints the TreeNodes encountered on a preorder traversal of an PTree
 * to a specified maximum depth. If the maximum depth is 0, then the 
 * entire tree is printed.
 */
void print_ptree(struct TreeNode *root, int max_depth) {
    // Here's a way to keep track of the depth (in the tree) you're at
    // and print 2 * that many spaces at the beginning of the line.
    static int depth = 0;
    if (root != NULL){
    	if (max_depth == 0){
    		if (root->name != NULL){
    			printf("%*s", depth * 2, "");
    			printf("%d: %s\n", root->pid, root->name);
    		}
    		else{
    			printf("%*s", depth * 2, "");
    			printf("%d", root->pid);
    		}

    		if (root->child != NULL){
    			depth++;
    			print_ptree(root->child, 0);
    			depth--;
    		}

    		if (root->sibling != NULL){
    			print_ptree(root->sibling, 0);
    		}
    	}
    	else if(max_depth > 0){
    		helper(root, 0, max_depth);
    	}
    }
}
