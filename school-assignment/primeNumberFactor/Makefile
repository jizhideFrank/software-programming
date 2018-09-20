FLAGS = -Wall -g -std=gnu99 


pfact : pfact.o
	gcc ${FLAGS} -o $@ $^ -lm

%.o: %.c ${DEPENDENCIES}
	gcc ${FLAGS} -c $<

clean: 
	rm -f *.o pfact

