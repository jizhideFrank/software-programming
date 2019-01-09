FLAGS = -Wall -g -std=gnu99

all : ext2_cp ext2_mkdir ext2_ln ext2_rm ext2_restore ext2_checker



#make executables
ext2_mkdir: ext2_utils.c ext2_mkdir.c
	gcc ${FLAGS} -o $@ $^

ext2_checker : ext2_utils.c ext2_checker.c
	gcc ${FLAGS} -o $@ $^

ext2_restore : ext2_utils.c ext2_restore.c
	gcc ${FLAGS} -o $@ $^
		  
ext2_cp : ext2_utils.c ext2_cp.c
	gcc ${FLAGS} -o $@ $^

ext2_ln : ext2_utils.c ext2_ln.c
	gcc ${FLAGS} -o $@ $^

ext2_rm : ext2_utils.c ext2_rm.c
	gcc ${FLAGS} -o $@ $^


clean : 
	rm -rf *.o ext2_cp ext2_mkdir ext2_ln ext2_rm ext2_restore ext2_checker
