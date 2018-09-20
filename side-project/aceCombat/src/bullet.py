
import pygame


class Bullet(pygame.sprite.Sprite):

    def __init__(self, position):
        super(Bullet, self).__init__()
        self.image = pygame.image.load("material/image/bullet1.png")
        # Fetch the rectangle object that has the dimentions of the image
        self.rect = self.image.get_rect()
        # Update the position of this object
        self.rect.left, self.rect.top = position
        
        self.speed = 30
        self.active = True
        #self.mask = pygame.mask.from_surface(self.image)

    def move(self):
        """
        if the bullet move out of the screen, then this bullet will be deactivated.
        """
        if self.rect.top < 0:
            self.active = False
        else:
            self.rect.top -= self.speed

    def reset(self, position):
        """
        Reset bullet into target position
        """
        self.rect.left, self.rect.top = position
        self.active = True



