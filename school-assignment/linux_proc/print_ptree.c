#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ptree.h"


int main(int argc, char **argv) {
    // TODO: Update error checking and add support for the optional -d flag
    // printf("Usage:\n\tptree [-d N] PID\n");
    // NOTE: This only works if no -d option is provided and does not
    // error check the provided argument or generate_ptree. Fix this!
    if (argc == 2){
        if (strcmp(argv[1], "-d") == 0){
        	fprintf(stderr, "wrong argument\n");
            return 1;
        }
        struct TreeNode *root = NULL;
        int first_case_result = generate_ptree(&root, strtol(argv[1], NULL, 10));
        print_ptree(root, 0);
        if (first_case_result == 0){
            return 0;
        }
        else{
            return 2;
        }
    }

    else if(argc == 4){
        if (strcmp(argv[1], "-d") != 0){
        	fprintf(stderr, "Usage:\n\tptree [-d N] PID\n");
            return 1;
        }
        else{
            struct TreeNode *root = NULL;
            int second_case_result = generate_ptree(&root, strtol(argv[3], NULL, 10));
            print_ptree(root, strtol(argv[2], NULL, 10));
            if (second_case_result == 0){
                return 0;
            }
            else{
                return 2;
            }
        }
    }

    else{
        fprintf(stderr, "wrong number of arguments\n");
        return 1;
    }
}
