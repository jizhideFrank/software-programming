import time

t0 = time.time()


# sudoku1 = [
#         0, 1, 0, 0, 0, 0, 6, 4, 0,
#         5, 0, 0, 1, 0, 3, 2, 8, 0,
#         0, 0, 0, 7, 5, 0, 0, 1, 0,
#         8, 0, 4, 3, 2, 5, 0, 0, 0,
#         9, 6, 0, 0, 0, 0, 7, 0, 0,
#         0, 0, 0, 9, 7, 6, 8, 5, 0,
#         6, 9, 8, 0, 3, 7, 4, 2, 1,
#         4, 2, 1, 0, 8, 9, 5, 0, 0,
#         3, 0, 7, 2, 4, 1, 0, 6, 0,
#     ]

# initialize a sudoku, and use 0 to represent empty spot
sudoku = [
        2, 0, 0, 6, 0, 3, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0, 0, 8,
        0, 5, 4, 0, 0, 0, 0, 0, 0,
        7, 0, 0, 5, 4, 6, 8, 0, 0,
        3, 0, 0, 0, 8, 9, 1, 0, 0,
        0, 0, 2, 0, 7, 0, 4, 9, 5,
        4, 0, 6, 0, 3, 2, 9, 5, 1,
        5, 2, 9, 1, 0, 4, 0, 8, 3,
        1, 8, 3, 9, 0, 7, 2, 0, 6,
    ]


class Point:
    def __init__(self, x, y):
        self.x_coordinate = x
        self.y_coordinate = y
        self.available = []
        self.value = 0

# check available number according to row
def check_row(point, sudoku):
    row = set(sudoku[point.y_coordinate * 9: (point.y_coordinate + 1) * 9])
    row.remove(0)
    return row

# check available number according to column
def check_column(point, sudoku):
    col = []
    length = len(sudoku)
    for i in range(point.x_coordinate, length, 9):
        col.append(sudoku[i])
    col = set(col)
    col.remove(0)
    return col

# check available number according to block
def check_block(point, sudoku):
    block_x = point.x_coordinate // 3
    block_y = point.y_coordinate // 3
    block = []
    start = block_y * 3 * 9 + block_x * 3
    for i in range(start, start + 3):
        block.append(sudoku[i])
    for i in range(start + 9, start + 9 + 3):
        block.append(sudoku[i])
    for i in range(start + 9 + 9, start + 9 + 9 + 3):
        block.append(sudoku[i])
    block = set(block)
    block.remove(0)
    return block

# check if certain point fit into the sudoku
def check_all(p, sudoku):
    if p.value == 0:
        return False
    if p.value not in check_row(p, sudoku) and \
            p.value not in check_column(p, sudoku) and \
            p.value not in check_block(p, sudoku):
        return True
    else:
        return False

# return all the blank spot of the sudoku
def blank_spot(sudoku):
    blank_spot_list = []
    length = len(sudoku)
    for i in range(length):
        if sudoku[i] == 0:
            p = Point(i % 9, i // 9)
            for j in range(1, 10):
                if j not in check_row(p, sudoku) and \
                        j not in check_column(p, sudoku) and \
                        j not in check_block(p, sudoku):
                    p.available.append(j)
            blank_spot_list.append(p)
    return blank_spot_list

# main algorithm
def tryInsert(p, sudoku):
    availNum = p.available
    for v in availNum:
        p.value = v
        if check_all(p, sudoku):
            sudoku[p.y_coordinate * 9 + p.x_coordinate] = p.value
            if len(pointList) <= 0:
                t1 = time.time()
                time_used = t1 - t0
                show_sudoku(sudoku)
                print('\ntime used: %f s' % (time_used))
                exit()
            p2 = pointList.pop()
            tryInsert(p2, sudoku)
            # if fail, reset point value to zero
            sudoku[p2.y_coordinate * 9 + p2.x_coordinate] = 0
            sudoku[p.y_coordinate * 9 + p.x_coordinate] = 0
            p2.value = 0
            pointList.append(p2)
        else:
            pass


def show_sudoku(sudoku):
    for j in range(9):
        for i in range(9):
            print('%d ' % (sudoku[j * 9 + i]), end='')
        print('')


if __name__ == '__main__':
    pointList = blank_spot(sudoku)
    show_sudoku(sudoku)
    print('\n')
    p = pointList.pop()
    tryInsert(p, sudoku)