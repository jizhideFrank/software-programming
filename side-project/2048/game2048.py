import random

# use two-dimension list to represent game board
v = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]

def display(v, score):
    """
    display game board
    :param v: list
    :param score: int
    :return: None
    """
    print('{0:4} {1:4} {2:4} {3:4}'.format(v[0][0], v[0][1], v[0][2], v[0][3]))
    print('{0:4} {1:4} {2:4} {3:4}'.format(v[1][0], v[1][1], v[1][2], v[1][3]))
    print('{0:4} {1:4} {2:4} {3:4}'.format(v[2][0], v[2][1], v[2][2], v[2][3]))
    print('{0:4} {1:4} {2:4} {3:4}'.format(v[3][0], v[3][1], v[3][2], v[3][3]), '    Total score: ', score)


def init(v):
    """
    initilize game board
    :param v:
    :return: None
    """
    for i in range(4):
        v[i] = [random.choice([0, 0, 0, 2, 2, 4]) for x in v[i]]


def eliminate_zeros(vList, direction):
    """
    assign number into correct location
    left and down are all treated as left
    right and up are all treated as right
    e.g. if we have [8, 0, 0, 2] in one row, after move left, result will be [8,2,0,0]
    e.g. if we have [8, 0, 0, 2] in one row, after move right, result will be [0,0,8,2]
    :param vList: list
    :param direction: string
    :return: None
    """
    for i in range(vList.count(0)):
        vList.remove(0)
    zeros = [0 for x in range(4 - len(vList))]
    # add zeros back into the position
    if direction == 'left':
        vList.extend(zeros)
    else:
        vList[:0] = zeros


def add_same(vList, direction):
    """
    add same number together
    left and down are all treated as left
    right and up are all treated as right
    :param vList: list
    :param direction: string
    :return: dictionary
    """
    score = 0
    if direction == 'left':
        for i in [0, 1, 2]:
            if vList[i] == vList[i + 1] != 0:
                vList[i] *= 2
                vList[i + 1] = 0
                score += vList[i]
                return {'bool': True, 'score': score}
    else:
        for i in [3, 2, 1]:
            if vList[i] == vList[i - 1] != 0:
                vList[i - 1] *= 2
                vList[i] = 0
                score += vList[i - 1]
                return {'bool': True, 'score': score}
    return {'bool': False, 'score': score}


def handle(vList, direction):
    """
    continuously move the list to left or right until there are no same numbers
    return the score
    :param vList: list
    :param direction: string
    :return: int
    """
    totalScore = 0
    eliminate_zeros(vList, direction)
    result = add_same(vList, direction)
    while result['bool'] == True:
        totalScore += result['score']
        eliminate_zeros(vList, direction)
        result = add_same(vList, direction)
    return totalScore


def operation(v):
    """
    main game logic
    :param v: list
    :return: dictionary
    """
    totalScore = 0
    gameOver = False
    direction = 'left'
    # take input from keyboard
    op = input('operator:')
    if op in ['a', 'A']:
        direction = 'left'
        for row in range(4):
            totalScore += handle(v[row], direction)
    elif op in ['d', 'D']:
        direction = 'right'
        for row in range(4):
            totalScore += handle(v[row], direction)
    elif op in ['w', 'W']:
        direction = 'left'
        for col in range(4):
            # handle the vertical list horizsontally
            vList = [v[row][col] for row in range(4)]
            totalScore += handle(vList, direction)
            # reset the value
            for row in range(4):
                v[row][col] = vList[row]
    elif op in ['s', 'S']:
        direction = 'right'
        for col in range(4):
            vList = [v[row][col] for row in range(4)]
            totalScore += handle(vList, direction)
            for row in range(4):
                v[row][col] = vList[row]
    else:
        print('Invalid input, please enter a charactor in [W, S, A, D]')
        return {'gameOver': gameOver, 'score': totalScore}

    # game ending logic
    number_of_zeros = 0
    for q in v:
        number_of_zeros += q.count(0)
    # if there is no blank space, end of game
    if number_of_zeros == 0:
        gameOver = True
        return {'gameOver': gameOver, 'score': totalScore}

    # generate one number from 2 or 4
    num = random.choice([2, 2, 2, 4])
    # randomly pick one blank spot to fill num
    k = random.randrange(1, number_of_zeros + 1)
    n = 0
    for i in range(4):
        for j in range(4):
            if v[i][j] == 0:
                n += 1
                if n == k:
                    v[i][j] = num
                    break

    return {'gameOver': gameOver, 'score': totalScore}



init(v)
score = 0
print('Input：W(Up) S(Down) A(Left) D(Right)')

# main game loop
while True:
    display(v, score)
    result = operation(v)
    if result['gameOver'] == True:
        print('Game Over, You failed!')
        print('Your total score:', score)
    else:
        score += result['score']
        if score >= 2048:
            print('Game Over, You Win!!!')