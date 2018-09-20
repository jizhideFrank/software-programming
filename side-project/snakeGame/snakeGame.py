
import random
import pygame
import sys
from pygame.locals import *

snake_speed = 15
window_width = 800
window_height = 500
grid_size = 10 

assert window_width % grid_size == 0, "Window width must be a multiple of grid size."
assert window_height % grid_size == 0, "Window height must be a multiple of grid size."
grid_number_horizontal = window_width / grid_size
grid_number_vertical = window_height / grid_size

HEAD = 0  # index of the snake's head


def main():
    global snake_speed_clock, display_surface, basic_font

    pygame.init()
    snake_speed_clock = pygame.time.Clock()
    display_surface = pygame.display.set_mode([window_width, window_height])
    basic_font = pygame.font.Font('freesansbold.ttf', 18)
    # program title name
    pygame.display.set_caption('Snake')
    show_start_screen()
    while True:
        run_game()
        show_game_over_screen()


# generate random location for food
def get_random_location():
    return {'x': random.randint(0, grid_number_horizontal - 1), 'y': random.randint(0, grid_number_vertical - 1)}

# check keyboard event
def check_key_press():
    event = pygame.event.get(KEYUP)
    if len(event) == 0:
        return None
    if event[0].key == K_ESCAPE:
        terminate()
    return event[0].key


def show_start_screen():

    gameStartFront = pygame.font.Font('freesansbold.ttf', 50)
    gameStartSurf1 = gameStartFront.render('welcome to the snake game', True, (255, 255, 0))
    gameStartSurf2 = gameStartFront.render(' ---- made by Yuan Xu', True, (255, 255, 0))
    gameStartSurf3 = gameStartFront.render('version 1.0', True, (255, 255, 0))
    while True:
        display_surface.fill((0, 0, 0))
        gameStartRect1 = gameStartSurf1.get_rect()
        gameStartRect2 = gameStartSurf2.get_rect()
        gameStartRect3 = gameStartSurf3.get_rect()

        gameStartRect1.midtop = (window_width / 2, 10)
        gameStartRect2.midtop = (window_width / 2, 80)
        gameStartRect3.midtop = (window_width / 2, 150)

        display_surface.blit(gameStartSurf1, gameStartRect1)
        display_surface.blit(gameStartSurf2, gameStartRect2)
        display_surface.blit(gameStartSurf3, gameStartRect3)

        drawPressKeyMsg()

        if check_key_press():
            pygame.event.get()  # clear event queue
            return
        pygame.display.update()
        snake_speed_clock.tick(snake_speed)


def show_game_over_screen():
    gameOverFont = pygame.font.Font('freesansbold.ttf', 100)

    gameSurf = gameOverFont.render('You are dead!', True, (255, 255, 255))
    overSurf = gameOverFont.render('Try again?', True, (255, 255, 255))

    gameRect = gameSurf.get_rect()
    overRect = overSurf.get_rect()

    gameRect.midtop = (window_width / 2, 40)
    overRect.midtop = (window_width / 2, 160)

    display_surface.blit(gameSurf, gameRect)
    display_surface.blit(overSurf, overRect)

    drawPressKeyMsg()

    pygame.display.update()
    pygame.time.wait(500)

    check_key_press()  # clear out any key presses in the event queue

    while True:
        if check_key_press():
            pygame.event.get()  # clear event queue
            return

# draw hint message in right bottom
def drawPressKeyMsg():
    pressKeySurf = basic_font.render('Press a key to play.', True, (255, 255, 255))
    pressKeyRect = pressKeySurf.get_rect()
    pressKeyRect.topleft = (window_width - 200, window_height - 30)
    display_surface.blit(pressKeySurf, pressKeyRect)


# draw the score indicator at the left top of the screen
def drawScore(score):
    scoreSurf = basic_font.render('Score: %s' % score, True, (255, 255, 255))
    scoreRect = scoreSurf.get_rect()
    scoreRect.topleft = (window_width - 120, 10)
    display_surface.blit(scoreSurf, scoreRect)


# draw snake in grid
def draw_snake(coordinate):
    for coord in coordinate:
        x = coord['x'] * grid_size
        y = coord['y'] * grid_size
        snakeRect = pygame.Rect(x, y, grid_size, grid_size)
        pygame.draw.rect(display_surface, (0, 155, 0), snakeRect)

# draw apple in single grid
def draw_apple(coordinate):
    x = coordinate['x'] * grid_size
    y = coordinate['y'] * grid_size
    appleRect = pygame.Rect(x, y, grid_size, grid_size)
    pygame.draw.rect(display_surface, (255, 0, 0), appleRect)

# make vertical and horizontal lines in the main window
def draw_grid():
    for x in range(0, window_width, grid_size):  # draw vertical lines
        pygame.draw.line(display_surface, (40, 40, 40), (x, 0), (x, window_height))
    for y in range(0, window_height, grid_size):  # draw horizontal lines
        pygame.draw.line(display_surface, (40, 40, 40), (0, y), (window_width, y))

def run_game():
    # Set a random start point.
    startx = random.randint(5, grid_number_horizontal - 6)
    starty = random.randint(5, grid_number_vertical - 6)
    snake_coordinates = [{'x': startx, 'y': starty},
                  {'x': startx - 1, 'y': starty},
                  {'x': startx - 2, 'y': starty}]
    direction = 'right'

    # Start the apple in a random place.
    apple = get_random_location()

    while True:  # main game loop
        for event in pygame.event.get():
            if event.type == QUIT:
                terminate()
            elif event.type == KEYDOWN:
                if (event.key == K_LEFT) and direction != 'right':
                    direction = 'left'
                elif (event.key == K_RIGHT) and direction != 'left':
                    direction = 'right'
                elif (event.key == K_UP) and direction != 'down':
                    direction = 'up'
                elif (event.key == K_DOWN) and direction != 'up':
                    direction = 'down'
                elif event.key == K_ESCAPE:
                    terminate()

        # game over condition
        # 1. snake hit the edge
        # 2. snake hit itself
        if snake_coordinates[HEAD]['x'] == -1 or snake_coordinates[HEAD]['x'] == grid_number_horizontal or snake_coordinates[HEAD]['y'] == -1 or \
                snake_coordinates[HEAD]['y'] == grid_number_vertical:
            return  # game over
        for wormBody in snake_coordinates[1:]:
            if wormBody['x'] == snake_coordinates[HEAD]['x'] and wormBody['y'] == snake_coordinates[HEAD]['y']:
                return  # game over

        # check if Snake has eaten an apply
        if snake_coordinates[HEAD]['x'] == apple['x'] and snake_coordinates[HEAD]['y'] == apple['y']:
            apple = get_random_location()  # set a new apple somewhere
        else:
            # always remove the tail segment
            del snake_coordinates[-1]  # remove worm's tail segment


        if direction == 'up':
            newHead = {'x': snake_coordinates[HEAD]['x'],
                       'y': snake_coordinates[HEAD]['y'] - 1}
        elif direction == 'down':
            newHead = {'x': snake_coordinates[HEAD]['x'],
                       'y': snake_coordinates[HEAD]['y'] + 1}
        elif direction == 'left':
            newHead = {'x': snake_coordinates[HEAD][
                                'x'] - 1, 'y': snake_coordinates[HEAD]['y']}
        elif direction == 'right':
            newHead = {'x': snake_coordinates[HEAD][
                                'x'] + 1, 'y': snake_coordinates[HEAD]['y']}

        # move the worm by adding a segment in the direction it is moving
        snake_coordinates.insert(0, newHead)

        display_surface.fill((0, 0, 0))
        draw_grid()
        draw_snake(snake_coordinates)
        draw_apple(apple)
        drawScore((len(snake_coordinates) - 3) * 10)
        pygame.display.update()
        snake_speed_clock.tick(snake_speed)

def terminate():
    pygame.quit()
    sys.exit()

if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        pass