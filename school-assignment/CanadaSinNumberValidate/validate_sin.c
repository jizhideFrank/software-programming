#include <stdio.h>
#include <stdlib.h>

int populate_array(int, int *);
int check_sin(int *);


int main(int argc, char **argv) {
    // TODO: Verify that command line arguments are valid.

    // TODO: Parse arguments and then call the two helpers in sin_helpers.c
    // to verify the SIN given as a command line argument.
  
    if (argc != 2 || argv[1][0] == '0'){
      printf("Invalid SIN\n");
      return 1;
    }

  	int sinNumberArray[9];
  	int sinNumber = strtol(argv[1], NULL, 10);
    if (populate_array(sinNumber, sinNumberArray) == 1){
      printf("Invalid SIN\n");
      return 1;
    }
    else{
      if (check_sin(sinNumberArray) == 0){
        printf("Valid SIN\n");
        return 0;
      }
      else{
        printf("Invalid SIN\n");
        return 1;
      }
    }
    
}
