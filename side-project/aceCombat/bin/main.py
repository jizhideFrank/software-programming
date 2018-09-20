#! /usr/bin/env python
# -*- coding: utf-8 -*-

import sys
from pygame.locals import *

# import sounds settings
from config.settings import *

from src.plane import OurPlane 
from src.enemy import SmallEnemy
from src.bullet import Bullet

# background size
bg_size = 480, 852  
screen = pygame.display.set_mode(bg_size) 
pygame.display.set_caption("Ace Combat")

background = pygame.image.load(os.path.join(BASE_DIR, "material/image/background.png"))  



color_black = (0, 0, 0)
color_green = (0, 255, 0)
color_red = (255, 0, 0)
color_white = (255, 255, 255)


our_plane = OurPlane(bg_size)


def add_small_enemies(group1, group2, num):
    """
    Add enemy to sprite group
    """
    for i in range(num):
        small_enemy = SmallEnemy(bg_size)
        group1.add(small_enemy)
        group2.add(small_enemy)


def main():
    # initialize music with infinite loop
    pygame.mixer.music.play(-1) 
    
    running = True
    switch_image = False
    delay = 60  

    # initialize sprite group of enemy plane
    enemies = pygame.sprite.Group() 
    small_enemies = pygame.sprite.Group()  
    # generate 6 enemy plane at each time
    add_small_enemies(small_enemies, enemies, 6) 

    bullet_index = 0
    e1_destroy_index = 0
    me_destroy_index = 0

    # initialize bullets
    bullet1 = []
    bullet_num = 6
    for i in range(bullet_num):
        bullet1.append(Bullet(our_plane.rect.midtop))

    while running:

        # draw backgroud
        screen.blit(background, (0, 0))

        # switch between two images
        clock = pygame.time.Clock()
        clock.tick(60)
        if not delay % 3:
            switch_image = not switch_image

        for each in small_enemies:
            # case where enemy plane is alive
            if each.active:
                each.move()
                screen.blit(each.image, each.rect)

                pygame.draw.line(screen, color_black,
                                 (each.rect.left, each.rect.top - 5),
                                 (each.rect.right, each.rect.top - 5),
                                 2)
                energy_remain = each.energy / SmallEnemy.energy
                if energy_remain > 0.2:
                    energy_color = color_green
                else:
                    energy_color = color_red
                pygame.draw.line(screen, energy_color,
                                 (each.rect.left, each.rect.top - 5),
                                 (each.rect.left + each.rect.width * energy_remain, each.rect.top - 5),
                                 2)
            
            # case where enemy plane is hit by bullet
            else:
                if e1_destroy_index == 0:
                    enemy1_down_sound.play()
                screen.blit(each.destroy_images[e1_destroy_index], each.rect)
                e1_destroy_index = (e1_destroy_index + 1) % 4
                if e1_destroy_index == 0:
                    each.reset()

        # case our plane alive and keep making bullet
        if our_plane.active:
            if switch_image:
                screen.blit(our_plane.image_one, our_plane.rect)
            else:
                screen.blit(our_plane.image_two, our_plane.rect)

            # Fire bullet every 10 frames
            if not (delay % 10):
                bullet_sound.play()
                bullets = bullet1
                bullets[bullet_index].reset(our_plane.rect.midtop)
                bullet_index = (bullet_index + 1) % bullet_num

            for b in bullets:
                if b.active: 
                    b.move()
                    screen.blit(b.image, b.rect)
                    # check if bullet hit enemy
                    enemies_hit = pygame.sprite.spritecollide(b, enemies, False, pygame.sprite.collide_mask)
                    
                    # if the bullet hit the enemy, both of the bullet and enemy plane disappear
                    if enemies_hit:  
                        b.active = False  
                        for e in enemies_hit:
                            e.active = False  

        # case where enemy hits us
        else:
            if not (delay % 3):
                screen.blit(our_plane.destroy_images[me_destroy_index], our_plane.rect)
                me_destroy_index = (me_destroy_index + 1) % 4
                if me_destroy_index == 0:
                    me_down_sound.play()
                    our_plane.reset()

        # updating the information if enemy hits us
        # plane.active and enemy.active will be False
        enemies_down = pygame.sprite.spritecollide(our_plane, enemies, False, pygame.sprite.collide_mask)
        if enemies_down:
            our_plane.active = False
            for e in enemies:
                e.active = False

        # Quit game operation by press ESC
        for event in pygame.event.get():
            if event.type == 12: 
                pygame.quit()
                sys.exit()

        if delay == 0:
            delay = 60
        delay -= 1

        # gain key pressed from user keyboard
        key_pressed = pygame.key.get_pressed()
        if key_pressed[K_w] or key_pressed[K_UP]:
            our_plane.move_up()
        if key_pressed[K_s] or key_pressed[K_DOWN]:
            our_plane.move_down()
        if key_pressed[K_a] or key_pressed[K_LEFT]:
            our_plane.move_left()
        if key_pressed[K_d] or key_pressed[K_RIGHT]:
            our_plane.move_right()

        # Update the full display Surface to the screen
        pygame.display.flip()




