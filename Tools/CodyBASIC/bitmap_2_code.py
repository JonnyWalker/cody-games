# python bitmap_2_code.py
#
# input: a 4 color bmp file
# only use the colors white, blue, red and black
import pygame
FILE = "sprites/ship.bmp"
LINE_NUMBER = 100
TRANSPARENT = (0xFF, 0xFF, 0xFF)  # White
COLOR01 = (0x00, 0x00, 0xFF)      # Blue
COLOR02 = (0xFF, 0x00, 0x00)      # RED
SHARED_COLOR = (0x00, 0x00, 0x00) # Black
SPRITE_W = 12
SPRITE_H = 21

pygame.init()
surface = None
with open(FILE) as file:
    surface = pygame.image.load_basic(file)
#CODY_SCREEN_W = 12
#CODY_SCREEN_H = 21
#SX = 10 # scale x
#SY = 10 # scale y 
#screen = pygame.display.set_mode((CODY_SCREEN_W*SX, CODY_SCREEN_H*SY))
#pygame.display.set_caption("Cody Bitmap Viewer")

# returns byte of four pixels
def get_sprite_data_4_pixel(x, y):
    value = 0
    for i in range(4):
        color = surface.get_at((x+i,y))
        if color == TRANSPARENT: 
            bits = 0b00
        elif color == COLOR01:
            bits = 0b01
        elif color == COLOR02:
            bits = 0b10
        elif color == SHARED_COLOR:
            bits = 0b11
        else:
            raise ValueError(str(color))
        value = (bits << (6-(i*2))) | value
    return value

# get all 63 bytes of sprite graphic
data = []
for j in range(SPRITE_H):
    for i in range(SPRITE_W//3 - 1):
        data.append(str(get_sprite_data_4_pixel(0+i*4, j)))
data.append(0) # force len 64 

# generate basic code
code = ""
index = 0
for _ in range(8):
    LINE_NUMBER += 10
    code += str(LINE_NUMBER)+" DATA " 
    for i in range(8):
        code += str(data[index])
        if i!=7:
            code += ","
        index += 1
    code += "\n"
print(code)

# draw image and wait for quit
#screen.blit(surface, (0,0)) 
#pygame.display.update()
#while True:
#   for event in pygame.event.get():
#      if event.type == pygame.QUIT:
#         pygame.quit()
#         sys.exit()