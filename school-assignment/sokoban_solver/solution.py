#   Look for #IMPLEMENT tags in this file. These tags indicate what has
#   to be implemented to complete the warehouse domain.

#   You may add only standard python imports---i.e., ones that are automatically
#   available on TEACH.CS
#   You may not remove any imports.
#   You may not import or otherwise source any of your own files

import os #for time functions
from search import * #for search engines
from sokoban import SokobanState, Direction, PROBLEMS #for Sokoban specific classes and problems

from scipy.optimize import linear_sum_assignment
import numpy as np

def sokoban_goal_state(state):
  '''
  @return: Whether all boxes are stored.
  '''
  for box in state.boxes:
    if box not in state.storage:
      return False
  return True

# assign each pair to the cloest storage
def heur_manhattan_distance(state):
#IMPLEMENT
    '''admissible sokoban puzzle heuristic: manhattan distance'''
    '''INPUT: a sokoban state'''
    '''OUTPUT: a numeric value that serves as an estimate of the distance of the state to the goal.'''
    #We want an admissible heuristic, which is an optimistic heuristic.
    #It must never overestimate the cost to get from the current state to the goal.
    #The sum of the Manhattan distances between each box that has yet to be stored and the storage point nearest to it is such a heuristic.
    #When calculating distances, assume there are no obstacles on the grid.
    #You should implement this heuristic function exactly, even if it is tempting to improve it.
    #Your function should return a numeric value; this is the estimate of the distance to the goal.
    result = 0
    for box in state.boxes:
      candidate_distance = []
      for storage in state.storage:
        m_dis = abs(storage[0] - box[0]) + abs(storage[1] - box[1])
        candidate_distance.append(m_dis)
      result += min(candidate_distance)
    return result


#SOKOBAN HEURISTICS
def trivial_heuristic(state):
  '''trivial admissible sokoban heuristic'''
  '''INPUT: a sokoban state'''
  '''OUTPUT: a numeric value that serves as an estimate of the distance of the state (# of moves required to get) to the goal.'''
  count = 0
  for box in state.boxes:
    if box not in state.storage:
        count += 1
  return count


## build the distance matrix by numpy
## return the lowest cost from box to storage
def assignment_function(state):
  whole_list = []
  for box in state.boxes:
    current = []

    for storage in state.storage:
      distance = abs(storage[0] - box[0]) + abs(storage[1] - box[1])
      current.append(distance)
    whole_list.append(current)
  
  cost = np.array(whole_list)
  row_ind, col_ind = linear_sum_assignment(cost)
  return cost[row_ind, col_ind].sum()


## remove all deadlock cases and call assignment function
def heur_alternate(state):
  for box in state.boxes:
    if box not in state.storage:
      if box_at_corner_of_two_walls(state, box): return float('inf')
      if two_boxes_stick_together_against_wall(state, box): return float('inf')
      if no_storage_along_wall(state, box): return float('inf')
      if box_stuck_by_3_obstacle(state, box): return float('inf')
      if blocked_along_wall(state, box): return float('inf')

  return assignment_function(state)


## return true box in the corner 
def box_at_corner_of_two_walls(state, box):
  if box == (0,0) or box == (0, state.height - 1) or box == (state.width - 1, 0) or box == (state.width - 1, state.height - 1):
    return True
  else:
    return False


# return True if two boxes stick together against wall
# return False as default
def two_boxes_stick_together_against_wall(state, box):
  # box stick to left wall
  if box[0] == 0:
    for other_box in state.boxes:
      if other_box[0] == 0:
        if other_box[1] == box[1] + 1 or other_box[1] == box[1] - 1:
          return True

  # box stick to right wall
  elif box[0] == state.width - 1:
    for other_box in state.boxes:
      if other_box[0] == state.width - 1:
        if other_box[1] == box[1] + 1 or other_box[1] == box[1] - 1:
          return True

  # box stick to bottom wall
  elif box[1] == 0:
    for other_box in state.boxes:
      if other_box[1] == 0:
        if other_box[0] == box[0] + 1 or other_box[0] == box[0] - 1:
          return True

  # box stick to top wall
  elif box[1] == state.height - 1:
    for other_box in state.boxes:
      if other_box[1] == state.height - 1:
        if other_box[0] == box[0] + 1 or other_box[0] == box[0] - 1:
          return True

  # default case
  else:
    return False

## return true if box is blocked by any three obstacle
def box_stuck_by_3_obstacle(state, box):
	## case 1
	obstacle_1 = (box[0] - 1, box[1] - 1)
	obstacle_2 = (box[0], box[1] - 1)
	obstacle_3 = (box[0] - 1, box[1])

	## case 2
	obstacle_4 = (box[0] + 1, box[1] + 1)
	obstacle_5 = (box[0], box[1] + 1)
	obstacle_6 = (box[0] + 1, box[1])

	## case 3
	obstacle_7 = (box[0] + 1, box[1])
	obstacle_8 = (box[0], box[1] - 1)
	obstacle_9 = (box[0] + 1, box[1] - 1)

	## case 4
	obstacle_10 = (box[0], box[1] + 1)
	obstacle_11 = (box[0] - 1, box[1])
	obstacle_12 = (box[0] - 1, box[1] + 1)



	if obstacle_1 in state.obstacles and obstacle_2 in state.obstacles and obstacle_3 in state.obstacles:
		return True
	if obstacle_4 in state.obstacles and obstacle_5 in state.obstacles and obstacle_6 in state.obstacles:
		return True

	if obstacle_7 in state.obstacles and obstacle_8 in state.obstacles and obstacle_9 in state.obstacles:
		return True

	if obstacle_10 in state.obstacles and obstacle_11 in state.obstacles and obstacle_12 in state.obstacles:
		return True
	return False


## return true if there is no storage along wall
## otherwise return false
def no_storage_along_wall(state, box):
	if box[0] == 0:
		counter = 0
		for storage in state.storage:
			if storage[0] == 0:
				counter += 1
		if counter == 0:
			return True

	elif box[0] == state.width - 1:
		counter = 0
		for storage in state.storage:
			if storage[0] == state.width - 1:
				counter += 1
		if counter == 0:
			return True

	elif box[1] == 0:
		counter = 0
		for storage in state.storage:
			if storage[1] == 0:
				counter += 1
		if counter == 0:
			return True

	elif box[1] == state.height - 1:
		counter = 0
		for storage in state.storage:
			if storage[1] == state.height - 1:
				counter += 1

		if counter == 0:
			return True

	else:
		return False

## return pair of number closest to the target vertically
def minimum_distance_vertical(list_of_y_value, my_y_value):
  greater = []
  smaller = []
  for num in list_of_y_value:
    if num > my_y_value:
      greater.append(num)
    else:
      smaller.append(num)

  nearest_value_above = 0
  nearest_value_bottom = 0
  if len(greater) == 0: 
    nearest_value_above += 9999
  else:
    nearest_value_above += min(greater)
  
  if len(smaller) == 0:
    nearest_value_bottom += 0
  else:
    nearest_value_bottom += max(smaller)
  
  return (nearest_value_above, nearest_value_bottom)

## return pair of number closest to the target horizontally
def minimum_distance_horizontal(list_of_x_value, my_x_value):
  greater = []
  smaller = []
  for num in list_of_x_value:
    if num > my_x_value:
      greater.append(num)
    else:
      smaller.append(num)

  nearest_value_left = 0
  nearest_value_right = 0
  if len(greater) == 0:
    nearest_value_right += 9999
  else:
    nearest_value_right += min(greater)

  if len(smaller) == 0:
    nearest_value_left += 0
  else:
    nearest_value_left += max(smaller)

  return (nearest_value_left, nearest_value_right)

## return true if the box is blocked along wall
## otherwise return false
def blocked_along_wall(state, box):
  if box[0] == 0:
    storage_y_value_list = []
    for storage in state.storage:
        if storage[0] == 0:
          storage_y_value_list.append(storage[1])
    tuple_of_nearest_value = minimum_distance_vertical(storage_y_value_list, box[1])

    indicator1 = 0
    indicator2 = 0
    for obstacle in state.obstacles:
      if box[1] < obstacle[1] < tuple_of_nearest_value[0]:
        indicator1 += 1
      if tuple_of_nearest_value[1] < obstacle[1] < box[1]:
        indicator2 += 1
      if indicator1 > 0 and indicator2 > 0:
        return True

  if box[0] == state.width - 1:
    storage_y_value_list = []
    for storage in state.storage:
      if storage[0] == state.width - 1:
        storage_y_value_list.append(storage[1])
    tuple_of_nearest_value = minimum_distance_vertical(storage_y_value_list, box[1])

    indicator1 = 0
    indicator2 = 0

    for obstacle in state.obstacles:
      if box[1] < obstacle[1] < tuple_of_nearest_value[0]:
        indicator1 += 1
      if tuple_of_nearest_value[1] < obstacle[1] < box[1]:
        indicator2 += 1
      if indicator1 > 0 and indicator2 > 0:
        return True

  if box[1] == 0:
    storage_x_value_list = []
    for storage in state.storage:
      if storage[1] == 0:
        storage_x_value_list.append(storage[0])
    tuple_of_nearest_value = minimum_distance_horizontal(storage_x_value_list, box[0])

    indicator1 = 0
    indicator2 = 0
    for obstacle in state.obstacles:
      if box[0] < obstacle[0] < tuple_of_nearest_value[1]:
        indicator1 += 1
      if tuple_of_nearest_value[0] < obstacle[0] < box[0]:
        indicator2 += 1

      if indicator1 > 0 and indicator2 > 0:
        return True

  if box[1] == state.height:
    storage_x_value_list = []
    for storage in state.storage:
      if storage[1] == state.height:
        storage_x_value_list.append(storage[0])
    tuple_of_nearest_value = minimum_distance_horizontal(storage_x_value_list, box[0])

    indicator1 = 0
    indicator2 = 0
    for obstacle in state.obstacles:
      if box[0] < obstacle[0] < tuple_of_nearest_value[1]:
        indicator1 += 1
      if tuple_of_nearest_value[0] < obstacle[0] < box[0]:
        indicator2 += 1

      if indicator1 > 0 and indicator2 > 0:
        return True

  return False
        
def heur_zero(state):
    '''Zero Heuristic can be used to make A* search perform uniform cost search'''
    return 0

def fval_function(sN, weight):
#IMPLEMENT
    """
    Provide a custom formula for f-value computation for Anytime Weighted A star.
    Returns the fval of the state contained in the sNode.

    @param sNode sN: A search node (containing a SokobanState)
    @param float weight: Weight given by Anytime Weighted A star
    @rtype: float
    """
  
    #Many searches will explore nodes (or states) that are ordered by their f-value.
    #For UCS, the fvalue is the same as the gval of the state. For best-first search, the fvalue is the hval of the state.
    #You can use this function to create an alternate f-value for states; this must be a function of the state and the weight.
    #The function must return a numeric f-value.
    #The value will determine your state's position on the Frontier list during a 'custom' search.
    #You must initialize your search engine object as a 'custom' search engine if you supply a custom fval function.
    
    return sN.gval + weight * sN.hval

def anytime_weighted_astar(initial_state, heur_fn, weight=1., timebound = 10):
#IMPLEMENT
  '''Provides an implementation of anytime weighted a-star, as described in the HW1 handout'''
  '''INPUT: a sokoban state that represents the start state and a timebound (number of seconds)'''
  '''OUTPUT: A goal state (if a goal is found), else False'''
  '''implementation of weighted astar algorithm'''
  start_time = os.times()[0]
  end_time = start_time + timebound
  
  output = False


  g_value = float('inf')
  h_value = float('inf')
  f_value = float('inf')

  while os.times()[0] < end_time:
    time_left = end_time - os.times()[0]
    astar_search_engine = SearchEngine("custom", "full")
    astar_search_engine.init_search(initial_state, sokoban_goal_state, heur_fn, lambda sN: fval_function(sN, weight))
    costbound = (g_value, h_value, f_value)
    result_from_search = astar_search_engine.search(time_left, costbound)

    if not result_from_search:
      break

    output = result_from_search
    f_value = result_from_search.gval

    if weight > 1:
      weight = weight / 2
    else:
      weight = 1

  return output


def anytime_gbfs(initial_state, heur_fn, timebound = 10):
#IMPLEMENT
  '''Provides an implementation of anytime greedy best-first search, as described in the HW1 handout'''
  '''INPUT: a sokoban state that represents the start state and a timebound (number of seconds)'''
  '''OUTPUT: A goal state (if a goal is found), else False'''
  '''implementation of weighted astar algorithm'''
  
  start_time = os.times()[0]
  end_time = start_time + timebound
  
  output = False


  g_value = float('inf')
  h_value = float('inf')
  f_value = float('inf')

  while os.times()[0] < end_time:
    time_left = end_time - os.times()[0]
    gbfs_search_engine = SearchEngine("best_first", "full")
    gbfs_search_engine.init_search(initial_state, sokoban_goal_state, heur_fn)
    costbound = (g_value, h_value, f_value)
    result_from_search = gbfs_search_engine.search(time_left, costbound)

    if not result_from_search:
      break

    output = result_from_search
    g_value = result_from_search.gval


  return output

  
