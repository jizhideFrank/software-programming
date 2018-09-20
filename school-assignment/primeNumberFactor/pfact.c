#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/wait.h>
#include <math.h>
// declare a integer array of size 2 as globle array
// store the two factors of given input
int factor_arr[2];


// helper function for the main program
void helper(int fd, int n){
	// static index for the factor_arr
	int static index = 0;
	// static indicator for how many prime factors found
	int static indicator = 0;
	
	int reading_from_parent;
	int val;


	int prime_factor = 0;


	int r =  read(fd, &reading_from_parent, sizeof(int));

	if (r == -1){
		perror("reading from pipe");
		exit(1);
	}


	if (reading_from_parent != 2 && reading_from_parent % 2 == 0 && reading_from_parent != n){
		helper(fd, n);
	}

	// case where input is a power of 2
	// and input is greater than 4
	// since 4 is a speical case (4 = 2 * 2)
	else if (reading_from_parent % 2 == 0 && reading_from_parent == n){
		if (reading_from_parent > 4){
			printf("%d is not the product of two primes.\n", n);
			exit(1);
		}
	}

	// successfully found one factor for the input
	// append this factor to the factor_arr
	// move the index pointer to the next position
	// otherwise keep the facotr unchanged
	if (n % reading_from_parent == 0){
		prime_factor = reading_from_parent;
		factor_arr[index] = prime_factor;
		index++;
	}

	// special case for perfect square
	// stop creating filter immediately
	// e.g. 4, 9, 25, 49
	if (prime_factor * prime_factor == n){
		printf("%d %d %d\n", n, prime_factor, prime_factor);
		exit(1);
	}

	// check if input has two prime factors
	// and these two prime factors are both less than
	// sqaure root of input
	// that implies input is not a product of two primes
	// stop creating filter immediately
	if (index == 2 && factor_arr[0] < sqrt(n) && factor_arr[1] < sqrt(n)){
		printf("%d is not the product of two primes.\n", n);
		exit(1);
	}

	// if n is equal to the last value from the reading
	// then n must be a prime number
	// e.g. input = 7
	// 2[3, 5, 7]
	if (reading_from_parent == n){
		printf("%d is prime\n", reading_from_parent);
		exit(1);
	}

	int helper_fd[2];
	int helper_result;
	int status;


	// keep fork for more process
	// iff p is no greater than the squre root of n
	if (reading_from_parent != 2 && reading_from_parent <= sqrt(n)){

		// error checking for pipe
		if (pipe(helper_fd) == -1){
			perror("pipe");
			exit(1);
		}

		// error checking for fork
		if ((helper_result = fork()) == -1){
      		perror("fork");
     		exit(1);
    	}


    	// child process
    	if (helper_result == 0){ 

    		if (close(helper_fd[1]) == -1){
    			perror("close writing for pipe");
    		}

    		// no prime factor found yet
    		// recursivly call the helper again
      		if (indicator != 1 && indicator != 2){
				helper(helper_fd[0], n);
      		}

      		if (close(helper_fd[0]) == -1){
    			perror("close reading for pipe");
    		}
    		
    		// only one prime factor found
      		if (indicator == 1){
				printf("%d is not the product of two primes.\n", n);
      		}

      		exit(1);  

    	}

    	else {
    	 	//parent process
    		close(helper_fd[0]);
      		while (read(fd, &val, sizeof(int)) > 0){
      			if (val % reading_from_parent != 0 && index != 2){
      				if (write(helper_fd[1], &val, sizeof(int)) != sizeof(int)){
      					close(helper_fd[1]);
      					if (close(helper_fd[1]) == -1){
      						perror("closing writing for pipe");
      						exit(1);
      					}
      				}

      				if (prime_factor * val == n && WEXITSTATUS(status) == -1){
      					printf("%d %d %d\n", n, prime_factor, val);
      				}
      			}
      		}

      		if (close(helper_fd[1])){
      			perror("close writing for pipe");
      			exit(1);
      		}
      		

      		// wait for the child process to finish
      		wait(&status);
      		if (WIFEXITED(status)){
      			// reading the output from child, 
      			// since the termination code of each process will be 
      			// one plus the number of filters follow it
      			exit(WEXITSTATUS(status) + 1);
      		}
      	}	

	}

	// we already have enough information about the input
	// no need to create new procress
	else{
		if (indicator == 2 || indicator == 1){
			if (factor_arr[0] * factor_arr[1] == n){
				printf("%d %d %d\n", n, factor_arr[0], factor_arr[1]);
			}

			else{
				printf("%d is not the product of two primes.\n", n);
			}

			exit(1);
		}

		helper(fd, n);
	}

}

int main(int argc, char **argv){

	char *re = NULL;
	
	int input = strtol(argv[1], &re, 10);


	// number of arguments must be 2
	// and the input integer must be greater than 1
	// since 1 is not a prime number or a composite number
	// input must be a positive integer
	if (argc != 2 || input <= 1 || strlen(re) != 0){
		fprintf(stderr, "Usage:\n\tpfact n\n");
		exit(1);
	}

	int status;
	int fd[2];

	// failed during pipe
	if (pipe(fd) == -1){
		perror("pipe");
		exit(1);
	}

	int result = fork();

	// failed during fork
	if (result == -1){
		perror("fork");
		exit(1);
	}

	// child process
	else if (result == 0){
		// close writing for the pipe
		if (close(fd[1]) == -1){
			perror("close writing for pipe");
			exit(1);
		}

		// call helper for the child process
		helper(fd[0], input);

		// close reading for pipe after call helper function
		if (close(fd[0]) == -1){
			perror("close reading for pipe");
			exit(1);
		}
	}

	// parent process
	else {
		// close reading for pipe
		if (close(fd[0]) == -1){
			perror("close reading for pipe");
			exit(1);
		}

		// writing array of integers staring at 2 and ending at input
		// e.g. if input = 5, write 2, 3, 4, 5 into the pipe
		for (int i = 2; i < input + 1; i++){
			if (write(fd[1], &i, sizeof(int)) == -1){
				perror("writing failed");
				exit(1);
			}
		}

		// close writing for pipe
		if (close(fd[1]) == -1){
			perror("close writing for pipe");
			exit(1);
		}
		
		// wait the child process to finish
		wait(&status);
		if (WIFEXITED(status)){
			// special case for 2, 3, 4
			// no filters are used for these three cases
			if (input == 2 || input == 3 || input == 4){
				fprintf(stderr, "Number of filters = %d\n", WEXITSTATUS(status) - 1);
				return 0;
			}

			// reading the output from child process
			fprintf(stderr, "Number of filters = %d\n", WEXITSTATUS(status));
		}
	}

	return 0;
}
