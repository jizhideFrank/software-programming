

from random import randint

import pygame


class SmallEnemy(pygame.sprite.Sprite):
    energy = 1

    def __init__(self, bg_size):
        super(SmallEnemy, self).__init__()
        self.image = pygame.image.load("material/image/enemy1.png")
        self.rect = self.image.get_rect()
        self.width, self.height = bg_size[0], bg_size[1]
        self.mask = pygame.mask.from_surface(self.image) 
        self.speed = 2
        self.energy = SmallEnemy.energy
        self.rect.left, self.rect.top = (
            randint(0, self.width - self.rect.width),  randint(-5 * self.rect.height, -5),
        )
        self.active = True
        self.destroy_images = []
        self.destroy_images.extend(
            [
                pygame.image.load("material/image/enemy1_down1.png"),
                pygame.image.load("material/image/enemy1_down2.png"),
                pygame.image.load("material/image/enemy1_down3.png"),
                pygame.image.load("material/image/enemy1_down4.png")
            ]
        )

    def move(self):

        if self.rect.top < self.height:
            self.rect.top += self.speed
        else:
            self.reset()

    def reset(self):
 
        self.rect.left, self.rect.top = (randint(0, self.width - self.rect.width), randint(-5 * self.rect.height, 0))
        self.active = True


class MidEnemy(pygame.sprite.Sprite):

    def __init__(self):
        super(MidEnemy, self).__init__()
        self.image = pygame.image.load("material/image/enemy2.png")


class BigEnemy(pygame.sprite.Sprite):

    def __init__(self):
        super(BigEnemy, self).__init__()
        self.image = pygame.image.load("material/image/enemy3.png")


