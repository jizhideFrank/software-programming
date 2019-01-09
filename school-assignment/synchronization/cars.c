#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "traffic.h"

extern struct intersection isection;

/**
 * Populate the car lists by parsing a file where each line has
 * the following structure:
 *
 * <id> <in_direction> <out_direction>
 *
 * Each car is added to the list that corresponds with 
 * its in_direction
 * 
 * Note: this also updates 'inc' on each of the lanes
 */
void parse_schedule(char *file_name) {
    int id;
    struct car *cur_car;
    struct lane *cur_lane;
    enum direction in_dir, out_dir;
    FILE *f = fopen(file_name, "r");

    /* parse file */
    while (fscanf(f, "%d %d %d", &id, (int*)&in_dir, (int*)&out_dir) == 3) {
        /* construct car */
        cur_car = malloc(sizeof(struct car));
        cur_car->id = id;
        cur_car->in_dir = in_dir;
        cur_car->out_dir = out_dir;

        /* append new car to head of corresponding list */
        cur_lane = &isection.lanes[in_dir];
        cur_car->next = cur_lane->in_cars;
        cur_lane->in_cars = cur_car;
        cur_lane->inc++;

        
    }

    fclose(f);
}

/**
 * TODO: Fill in this function
 *
 * Do all of the work required to prepare the intersection
 * before any cars start coming
 * 
 */
void init_intersection() {

    for (int i = 0; i < 4; i++) {
	// initialize four quads
	pthread_mutex_init(&isection.quad[i], NULL);

    	// initalize four lanes
        pthread_mutex_init(&isection.lanes[i].lock, NULL);
        pthread_cond_init(&isection.lanes[i].producer_cv, NULL);
        pthread_cond_init(&isection.lanes[i].consumer_cv, NULL);
        isection.lanes[i].in_cars = NULL;
        isection.lanes[i].out_cars = NULL;
        isection.lanes[i].inc = 0;
        isection.lanes[i].passed = 0;
        isection.lanes[i].buffer = malloc(sizeof(struct car*) * LANE_LENGTH);
        isection.lanes[i].head = 0;
        isection.lanes[i].tail = -1;
        isection.lanes[i].capacity = LANE_LENGTH;
        isection.lanes[i].in_buf = 0;



    }

}


/**
 * TODO: Fill in this function
 *
 * Populates the corresponding lane with cars as room becomes
 * available. Ensure to notify the cross thread as new cars are
 * added to the lane.
 * 
 */
void *car_arrive(void *arg) {
    struct lane *l = arg;

    while(1){
        pthread_mutex_lock(&l->lock); 

        // unlock the mutex and return NULL when there is no car arriving
        if (l->inc == 0 || l->in_cars == NULL) {
            pthread_mutex_unlock(&l->lock);
            return NULL;
        }

        struct car * current = l->in_cars;

        // wait producer when the number of elements in the list is full
        while(l->in_buf == l->capacity){  
            pthread_cond_wait(&l->producer_cv, &l->lock); 

        }

        // update tail, reset tail to 0 if it reaches the maximum capacity
        l->tail += 1;
        if (l->tail >= l->capacity) {
            l->tail = 0;
        }

        // add current car into buffer
        l->buffer[l->tail] = current; 
        l->in_buf += 1; 
        l->in_cars = l->in_cars->next;    
        
        // decrease number of cars passed through by 1
        l->inc--; 

        pthread_cond_signal(&l->consumer_cv);
        pthread_mutex_unlock(&l->lock);
    }

    return NULL;
}

/**
 * TODO: Fill in this function
 *
 * Moves cars from a single lane across the intersection. Cars
 * crossing the intersection must abide the rules of the road
 * and cross along the correct path. Ensure to notify the
 * arrival thread as room becomes available in the lane.
 *
 * Note: After crossing the intersection the car should be added
 * to the out_cars list of the lane that corresponds to the car's
 * out_dir. Do not free the cars!
 *
 * 
 * Note: For testing purposes, each car which gets to cross the 
 * intersection should print the following three numbers on a 
 * new line, separated by spaces:
 *  - the car's 'in' direction, 'out' direction, and id.
 * 
 * You may add other print statements, but in the end, please 
 * make sure to clear any prints other than the one specified above, 
 * before submitting your final code. 
 */
void *car_cross(void *arg) {
    struct lane *l = arg;

    while(1){
        pthread_mutex_lock(&l->lock);

        // unlock the mutex and return NULL when there is no car crossing
        if (l->in_cars == NULL && l->in_buf == 0) {
            free(l->buffer);
            pthread_mutex_unlock(&l->lock);
            return NULL;
        }

        // wait consumer when the number of elements in the list is zero
        while(l->in_buf == 0){
            pthread_cond_wait(&l->consumer_cv, &l->lock);
        }

        int head_index = l->head;
        struct car* temp_car = l->buffer[head_index];

        // update head, reset head to 0 if it reaches the maximum capacity
        l->head += 1;
        if (l->head >= l->capacity) {
            l->head = 0;
        }

        // decrease number of cars currently in the list by 1
        // increase number of cars passed by 1
        l->in_buf--; 
        l->passed++;

        struct lane* car_leaving_lane = &isection.lanes[temp_car->out_dir];

        pthread_mutex_unlock(&l->lock);
        
        // generate path
        int* path = compute_path(temp_car->in_dir, temp_car->out_dir);

        // lock the corresbonding region if the value is not 1
        for(int i = 0; i < 4; i++){
            if(path[i] != -1){
                pthread_mutex_lock(&(isection.quad[path[i]-1]));
            }
        }

        pthread_mutex_lock(&car_leaving_lane->lock); 

        temp_car->next = car_leaving_lane->out_cars; 
        
        // add temp_car to the list of cars that have passed the intersection into this lane
        car_leaving_lane->out_cars = temp_car;
        car_leaving_lane->passed++;
        
        pthread_mutex_unlock(&car_leaving_lane->lock); 
        
        printf("%d %d %d\n", temp_car->in_dir, temp_car->out_dir, temp_car->id);

        // unlock the corresbonding region
        for(int i = 0; i < 4; i++){
            if(path[i] != -1){
                pthread_mutex_unlock(&(isection.quad[path[i]-1]));
            }
        }

        // free the dynamically allocated space
        free(path); 

        pthread_mutex_lock(&l->lock);
        pthread_cond_signal(&l->producer_cv);
        pthread_mutex_unlock(&l->lock);
    
    }

    
}

/**
 * TODO: Fill in this function
 *
 * Given a car's in_dir and out_dir return a sorted 
 * list of the quadrants the car will pass through.
 * 
 */
int *compute_path(enum direction in_dir, enum direction out_dir) {

    // dynamically alocate the array of size 4
    int * path_arr = malloc(sizeof(int) * 4);
    
    // set all value to default -1
    for (int i = 0; i < 4; i++) {
        path_arr[i] = -1;
    }

    // case if in_dir is north
    if (in_dir == NORTH) {

        if (out_dir == NORTH) {
            path_arr[0] = 1; path_arr[1] = 2; path_arr[2] = 3; path_arr[3] = 4;
        }

        else if (out_dir == WEST) {
            path_arr[0] = 2;

        }

        else if (out_dir == SOUTH) {
            path_arr[0] = 2; path_arr[1] = 3;

        }

        else if (out_dir == EAST) {
            path_arr[0] = 2; path_arr[1] = 3; path_arr[2] = 4;

        }

        else {
            return NULL;
        }
    }

    // case if in_dir is west
    else if (in_dir == WEST) {
        if (out_dir == NORTH) {
            path_arr[0] = 1; path_arr[1] = 3; path_arr[2] = 4;
        }

        else if (out_dir == WEST) {
            path_arr[0] = 1; path_arr[1] = 2; path_arr[2] = 3; path_arr[3] = 4;
        }

        else if (out_dir == SOUTH) {
            path_arr[0] = 3;

        }

        else if (out_dir == EAST) {
            path_arr[0] = 3; path_arr[1] = 4;

        }

        else {
            return NULL;
        }
    }

    // case if in_dir is south
    else if (in_dir == SOUTH) {

        if (out_dir == NORTH) {
            path_arr[0] = 1; path_arr[1] = 4;

        }

        else if (out_dir == WEST) {
            path_arr[0] = 1; path_arr[1] = 2; path_arr[2] = 4;

        }

        else if (out_dir == SOUTH) {
            path_arr[0] = 1; path_arr[1] = 2; path_arr[2] = 3; path_arr[3] = 4;

        }

        else if (out_dir == EAST) {
            path_arr[0] = 4;
        }

        else {
            return NULL;
        }

    }

    // case if in_dir is east
    else if (in_dir == EAST) {

        if (out_dir == NORTH) {
            path_arr[0] = 1;
        }

        else if (out_dir == WEST) {
            path_arr[0] = 1; path_arr[1] = 2;
        }

        else if (out_dir == SOUTH) {
            path_arr[0] = 1; path_arr[1] = 2; path_arr[2] = 3;

        }

        else if (out_dir == EAST) {
            path_arr[0] = 1; path_arr[1] = 2; path_arr[2] = 3; path_arr[3] = 4;

        }

        else {
            return NULL;
        }

    }

    else {
        return NULL;
    }

    return path_arr;
}
