#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define MAXNAME 80  /* maximum permitted name size, not including \0 */
#define NPITS 6  /* number of pits on a side, not including the end pit */
#define NPEBBLES 4 /* initial number of pebbles per pit */
#define MAXMESSAGE (MAXNAME + 50) /* initial number of pebbles per pit */

int port = 9558;
int listenfd;

struct player {
    int fd;
    char name[MAXNAME+1];
    int pits[NPITS+1];  // pits[0..NPITS-1] are the regular pits
                        // pits[NPITS] is the end pit
    int turn_indicator; // 1 if it is your turn, 0 otherwise
    struct player *next;
};
struct player *playerlist = NULL;

extern void parseargs(int argc, char **argv);
extern void makelistener();
extern int compute_average_pebbles();
extern int game_is_over();  /* boolean */
extern void notify(int fd, char *msg);
extern void display();
extern void broadcast(char *s); 
extern void display_whose_turn();
extern void distribute(struct player *current_player, int *pit, int *pebbles);
extern int move(struct player *current_player, int pit);
extern int make_move_by_player(int current_turn_player_fd);
extern void set_next_turn(struct player *player);
extern int check_connetion(int fd);
extern void connection_lost(int fd);
extern int check_exist(char *user_name);
extern int find_new_line_character(char *client_input);
extern int check_next();
extern int accept_connection(int listenfd);
extern int add_first_player(int fd);
extern int add_new_player(int new_fd);
extern void valid_move(struct player *current, int pit_num);

int main(int argc, char **argv) {
    char msg[MAXMESSAGE];
    struct player *current;

    parseargs(argc, argv);
    makelistener();

    fd_set all_fds;
    FD_ZERO(&all_fds);
    FD_SET(listenfd, &all_fds);
    int max_fd;

    // add the first player for the game
    int client_fd = add_first_player(listenfd);
    

    if (client_fd >= 0){
        FD_SET(client_fd, &all_fds);
        max_fd = client_fd;
    }

    else{
        printf("first player disconnected\n");
    }

    while (!game_is_over()) {
        fd_set copy_fds = all_fds;

        display_whose_turn();
        display();

        int ready = select(max_fd + 1, &copy_fds, NULL, NULL, NULL);
        if (ready == -1) {
            perror("server: select");
            exit(1);
        }

        // when fd_isset is ready, accpet new player from client
        if (FD_ISSET(listenfd, &copy_fds)) {
            int result = accept_connection(listenfd);
            if (result != -1) {
                if (result > max_fd) {
                    max_fd = result;
                }
                FD_SET(result, &all_fds);
                printf("Wlcome the new player with fd %d\n", result);
                int status = add_new_player(result);
                if (status > 0) {
                    FD_CLR(status, &all_fds);
                    char msg[MAXMESSAGE];
                    sprintf(msg, "A player with fd %d disconnected.\r\n", status);
                    printf("A player with fd %d disconnected.\n", status);
                }
            } 

            // case where player failed to connect with server
            else {
                exit(1);
            }
        }

        current = playerlist;
        while (current != NULL) {
            if (FD_ISSET(current->fd, &copy_fds)) {
    
                // case where player should make a move
                if (current->turn_indicator == 1) {
                    char *message;
                    //char msg[MAXMESSAGE];


                    int pit_num = make_move_by_player(current->fd);
                    
                    // Player choose a valid pit
                    if (pit_num >= 0) {
                        valid_move(current, pit_num);
                    } 

                    // player disconnted during typing;
                    else if (pit_num == -2) {
                        char msg[MAXMESSAGE];
                        sprintf(msg, "%s disconnected.\r\n", current->name);
                        printf("%s disconnected.\n", current->name);
                        
                        // fix the connection
                        connection_lost(current->fd);
                        
                        // set the next turn player
                        set_next_turn(current->next);
                        FD_CLR(current->fd, &all_fds);
                        free(current);
                        broadcast(msg);
                    } 

                    // player enter an invalid pit number;
                    else {
                        message = "Please enter a valid pit number.\r\n";
                        notify(current->fd, message);
                    }
                }


                // case where player should not make move 
                else if (current->turn_indicator == 0) {

                    // if player already disconnected
                    int status = check_connetion(current->fd);
                    if (status > 0){
                        char msg[MAXMESSAGE];
                        sprintf(msg, "player %s disconnected.\r\n", current->name);
                        printf("Player %s disconnected.\n", current->name);
                        connection_lost(status);
                        FD_CLR(status, &all_fds);
                        free(current);
                        broadcast(msg);
                    }

                    // case where player still online
                    char *message = "Please wait until your turn.\r\n";
                    notify(current->fd, message);

                }
            }

            // loop over the whole playerlist
            current = current->next;
        }
    }

    broadcast("Game over!\r\n");
    printf("Game over!\n");
    for (struct player *p = playerlist; p; p = p->next) {
        int points = 0;
        for (int i = 0; i <= NPITS; i++) {
            points += (p->pits)[i];
        }
        printf("%s has %d points\r\n", p->name, points);
        snprintf(msg, MAXMESSAGE, "%s has %d points\r\n", p->name, points);
        broadcast(msg);
    }
    return 0;
}



void parseargs(int argc, char **argv) {
    int c, status = 0;
    while ((c = getopt(argc, argv, "p:")) != EOF) {
        switch (c) {
        case 'p':
            port = strtol(optarg, NULL, 0);
            break;
        default:
            status++;
        }
    }
    if (status || optind != argc) {
        fprintf(stderr, "usage: %s [-p port]\n", argv[0]);
        exit(1);
    }
}


void makelistener() {
    struct sockaddr_in r;

    if ((listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        perror("socket");
        exit(1);
    }

    int on = 1;
    if (setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR,
               (const char *) &on, sizeof(on)) == -1) {
        perror("setsockopt");
        exit(1);
    }

    memset(&r, '\0', sizeof(r));
    r.sin_family = AF_INET;
    r.sin_addr.s_addr = INADDR_ANY;
    r.sin_port = htons(port);
    if (bind(listenfd, (struct sockaddr *)&r, sizeof(r))) {
        perror("bind");
        exit(1);
    }

    if (listen(listenfd, 5)) {
        perror("listen");
        exit(1);
    }
}



/* call this BEFORE linking the new player in to the list */
int compute_average_pebbles() {
    struct player *p;
    int i;

    if (playerlist == NULL) {
        return NPEBBLES;
    }

    int nplayers = 0, npebbles = 0;
    for (p = playerlist; p; p = p->next) {
        nplayers++;
        for (i = 0; i < NPITS; i++) {
            npebbles += (p->pits)[i];
        }
    }
    return ((npebbles - 1) / nplayers / NPITS + 1);  /* round up */
}


int game_is_over() { /* boolean */
    int i;

    if (!playerlist) {
       return 0;  /* we haven't even started yet! */
    }

    for (struct player *p = playerlist; p; p = p->next) {
        int is_all_empty = 1;
        for (i = 0; i < NPITS; i++) {
            if (p->pits[i]) {
                is_all_empty = 0;
            }
        }
        if (is_all_empty) {
            return 1;
        }
    }
    return 0;
}


// send message to single person
// e.g.
// ask for player's name or their moves
void notify(int fd, char *msg){
    write(fd, msg, strlen(msg));
}



// display the current situation for current play
void display(){
    char buf[MAXMESSAGE];
    snprintf(buf, MAXMESSAGE, "%s:  [0]%d [1]%d [2]%d [3]%d [4]%d [5]%d  [end pit]%d\n", playerlist->name, playerlist->pits[0], 
        playerlist->pits[1], playerlist->pits[2], playerlist->pits[3], 
        playerlist->pits[4], playerlist->pits[5], playerlist->pits[6]);
    broadcast(buf);
}



// broadcast message to each user.
void broadcast(char *s){
    struct player *current = playerlist;
    while (current != NULL){
        write(current->fd, s, strlen(s));
        current = current->next;
    }
}


// broadcast to all the player who is currently on the turn
void display_whose_turn(){
    struct player *current = playerlist;
    // loop over the linkedlist, find the player who is current on turn
    while (current->turn_indicator != 1) {
        current = current->next;
    }

    char *message = "Your turn.\r\n";
    
    notify(current->fd, message);
    
    char msg[MAXMESSAGE];
    
    sprintf(msg, "%s's turn!\r\n", current->name);
    
    broadcast(msg);
}



// distribute pebbles until there is no more pebbles 
// or reach the end pit
void distribute(struct player *current_player, int *pit, int *pebbles){
    while (*pebbles > 0 && *pit <= NPITS) {
        (current_player->pits)[*pit] += 1;
        *pebbles -= 1;
        *pit += 1;
    }
}

// game logic
// move all the pebbles in the target pit
// distribute pebbles in the following pits one by one
// until number of pebbles is zero
// check the pointer for both pit and pebbles
// return -1 if player choose empty pit
// return 1 for extra turn
// return 0 for normal turn
int move(struct player *current_player, int n) {
    int pebbles = current_player->pits[n];
    if (pebbles == 0) {
        // case where player choose an empty pit position;
        return -1;
    }

    // set the target position to 0;
    (current_player->pits)[n] = 0;

    n = n + 1;
    while (pebbles > 0) {
        distribute(current_player, &n, &pebbles);
        if (pebbles == 0) {
            n -= 1;
            break;
        }

        // where target player has a next player;
        if (current_player-> next != NULL) {
            current_player = current_player->next;
        }
        // where taget player is the last player;
        else {
            current_player = playerlist;
        }
        n = 0;
    }

    //extra turn for the player;
    if (n == NPITS) {
        
        return 1;
    } 

    // no extra turn;
    else {
        return 0;
    }
}


// return -1 if player choose a pit smaller than zero or greater than 5
// otherwise return the pit position chosen by the player
int make_move_by_player(int fd) {
    char movement[MAXMESSAGE];
    int n = read(fd, movement, MAXMESSAGE);

    // nothing is read from player, which implies disconnected;
    if (n == 0) {
        return -2;
    }
    int pit = find_new_line_character(movement);
    movement[pit] = '\0';
    int pit_num = strtol(movement, NULL, 10);

    if (pit_num < 0 || pit_num > 5) {
        return -1;
    } else {
        return pit_num;
    }
}



// prepare for the player who is on the next turn
// change the turn_indicator into 1;
void set_next_turn(struct player *current){
    if (current != NULL && current->turn_indicator == 0){
        current->turn_indicator = 1;
    }
    else if (current == NULL){
        set_next_turn(playerlist);
    }
    else{
        set_next_turn(current->next);
    }

}


// check if the player still conneted
// return 0 if still online
// otherwise return the fd
int check_connetion(int fd){
    char status[MAXMESSAGE];

    int num_read = read(fd, &status, MAXMESSAGE);

    status[num_read] = '\0';
    
    // player disconnected if nothing is read from player
    // or cannot write anything to the player;
    if (num_read == 0 || write(fd, status, strlen(status)) != strlen(status)){
        return fd;
    }
    // player still online;
    else{
        return 0;
    }
}



// re-establish the linkedlist when player quit the game;
// change the pointer on next for the player;
void connection_lost(int fd){
    struct player *current = playerlist;
    if (current->fd != fd){
        // find the connection lost
        while ((current->next)->fd != fd){
            current = current->next;
        }
        // change the pointer;
        current->next = (current->next)->next;
    }
    // keep looping the linkedlist
    else{
        playerlist = current->next;
    }
}



// check if username is repteated
// return 1 if it is, otherwise return 0;
int check_exist(char *user_name) {
    struct player *current = playerlist;
    int repeat = 0;
    while (current != NULL) {
    
        if (strcmp(user_name, current->name) == 0) {
            repeat = 1;
            break;
        }
        
        current = current->next;
    }
    return repeat;
}




// return the index position of /r or /n
// return -1 if cannot find;
int find_new_line_character(char *input) {
    char a = '\r';
    char b = '\n';
    char *ptr;
    int index;
    if ((ptr = strchr(input, a)) != NULL) {
        index = ptr - input;
        return index;
    } 

    else if ((ptr = strchr(input, b)) != NULL) {
        index = ptr - input;
        return index;
    } 

    else {
        return -1;
    }
}


int check_next() {
    struct player *player = playerlist;
    while (player != NULL) {
        if (player->turn_indicator >= 0) {
            return 1;
        }
        player = player->next;
    }
    return 0;
}


// accept connection from client
// return -1 if there problem occurs during accept
// otherwise return cliend_fd
int accept_connection(int fd){
    
    int client_fd = accept(fd, NULL, NULL);
    if (client_fd < 0){
        perror("error in new connection");
        close(fd);
        return -1;
    }

    char *msg = "Welcome to Mancala. What is your name?\r\n";
    notify(client_fd, msg);

    return client_fd;
}


// add first new player into the linkedlist
// return the cliend fd if the player succesfully connect to the server
// return -3 if player failed to connect to the server
// return -2 if player not finish typing username
// return -1 if player disconencted

int add_first_player(int fd) {
    int client_fd = accept_connection(fd);
    if (client_fd == -1) {
        return -3;
    }
    char name[MAXNAME];
    int n = read(client_fd, name, MAXNAME);
    

    // case where nothing is read from the client
    if (n == 0) {
        printf("New player disconnected");
        return -1;
    }

    // malloc space for new player;
    struct player *new_player = malloc(sizeof(struct player));
    
    new_player->turn_indicator = 1;
    new_player->fd = client_fd;
    new_player->next = NULL;

    int amount = compute_average_pebbles();
    for (int i = 0; i < 6; i++) {
        new_player->pits[i] = amount;
    }

    playerlist = new_player;


    // check the index for new line character
    int index = find_new_line_character(name);
    if (index != -1) {
        name[index] = '\0';
        
        strcpy(new_player->name, name);
        
        char buffer[MAXMESSAGE];
        
        sprintf(buffer, "New player %s has joined the session.\r\n", name);
       
        notify(client_fd, buffer);
        
        printf("New player %s has joined the session.\n", name);
        
        return client_fd;
    }  

    // case where player not finish typing their name;
    else {
        name[n] = '\0';
        strcpy(new_player->name, name);
        return -2;
    }
}


// add a new player for the game
// return player's fd if fail
// otherwise return 0
int add_new_player(int new_fd) {
    char buf[MAXNAME + 1];
    int n = read(new_fd, buf, MAXNAME + 1);
    
    // nothing is read from client
    if (n == 0) {
        char msg[MAXMESSAGE];
        sprintf(msg, "Player %d has disconnected.\r\n", new_fd);
        printf("Player %d has disconnected.\n", new_fd);
        return new_fd;
    }
    struct player *new_player = malloc(sizeof(struct player *));

    int location = find_new_line_character(buf);
    if (location == -1) {
        if (n <= MAXNAME) {
            buf[n] = '\0';
            strcpy(new_player->name, buf);

            new_player->turn_indicator = -2;
            
        } 

    } else {
        buf[location] = '\0';
        if(check_exist(buf) == -1){
            new_player->turn_indicator = -1;
            char *message = "Name already exist, please pick a different name.\r\n";
            notify(new_fd, message);
        } else {
            if (!check_next()) {
                new_player->turn_indicator = 1;
            } else {
                new_player->turn_indicator = 0;
            }
            strcpy(new_player->name, buf);
            char buffer[MAXMESSAGE];
            sprintf(buffer, "Player %s joined the game.\r\n", buf);
            broadcast(buffer);
            printf("Player %s joined the game.\n", buf);
        }
    }

    // initialize information for the new player
    new_player->fd = new_fd;
    new_player->next = playerlist;

    int amount = compute_average_pebbles();
    for (int i = 0; i < 6; i++) {
        new_player->pits[i] = amount;
    }
    
    playerlist = new_player;
    return 0;
}

// condition where it is player's turn 
// and player enter a valid input;
void valid_move(struct player *current, int pit_num){
    char *message;
    char msg[MAXMESSAGE];


    int result = move(current, pit_num);

    if (result == -1){
        message = "Empty pit, please choose another one.\r\n";
        notify(current->fd, message);
    }

    else if (result == 0){
        current->turn_indicator = 0;
        sprintf(msg, "%s has cleared out %d pit\r\n", current->name, pit_num);
        printf("%s has cleared out %d pit\r\n", current->name, pit_num);
        broadcast(msg);
        set_next_turn(current->next);
    }

    else if (result == 1){
        message = "Extra Turn!!!\r\n";
        sprintf(msg, "%s gets an extra turn!\r\n", current->name);
        printf("%s gets an extra turn!\r\n", current->name);
        broadcast(msg);
        notify(current->fd, message);
    }
}
