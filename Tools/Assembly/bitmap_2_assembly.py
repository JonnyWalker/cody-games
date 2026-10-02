# input: a 160x200 pixel bitmap file, only using "cody compatible colors" (see below)
# output: 65c02 assembly compatible pixel and color bytes
import pygame

# define cody compatible colors
BLACK       = (0,     0,   0, 255)
WHITE       = (255, 255, 255, 255) 
RED         = (255,   0,   0, 255) 
CYAN        = (0,   255, 255, 255)
PURPLE      = (128,   0, 128, 255)
GREEN       = (0,   255,   0, 255)
BLUE        = (0,     0, 255, 255)
YELLOW      = (255, 255,   0, 255)
ORANGE      = (224, 160,   0, 255)
BROWN       = (128,  96,  64, 255)
LIGHT_RED   = (224, 192, 128, 255)
DARK_GRAY   = (96,   96,  96, 255)
GRAY        = (128, 128, 128, 255)
LIGHT_GREEN = (160, 224, 128, 255)
LIGHT_BLUE  = (192, 220, 192, 255)
LIGHT_GRAY  = (196, 196, 196, 255)
COMPATIBLE_COLORS = [BLACK, WHITE, RED, CYAN,
                     PURPLE, GREEN, BLUE, YELLOW,
                     ORANGE, BROWN, LIGHT_RED, DARK_GRAY,
                     GRAY, LIGHT_GREEN, LIGHT_BLUE, LIGHT_GRAY]
COLOR_MAP = {x:i for i, x in enumerate(COMPATIBLE_COLORS)}
tile_conter = 0 

# edit those line
FILE = "tiles/pitaya.bmp"
SHARED_COLOR11 = BLACK
SHARED_COLOR10 = WHITE

# init
pygame.init()
surface = None
with open(FILE) as file:
    surface = pygame.image.load_basic(file)

# check size
width, height = surface.get_size()
if width < 4 or width % 4 != 0 or height<8 or height % 8 != 0 :
    print("Error. Picture width musst be multiple of 4")
    print("Your resolution:", surface.get_size())
    exit(0)
if height < 8 or height % 8 != 0 :
    print("Error. Picture height musst be multiple of 8")
    print("Your resolution:", surface.get_size())
    exit(0)

# check colors
for y in range(height):
    for x in range(width):
        color = surface.get_at((x,y))
        illegal_color = True
        for c in COMPATIBLE_COLORS:
            if c == color:
                illegal_color = False
        if illegal_color:
            print("Error. Illegal color ",color, " at ", (x,y))
            exit(0)

# [x1,x2[ and [y1,y2[
def compute_pixels_and_color(x1,x2,y1,y2):
    # analyize colors of 4x8 pixel tile 
    # and compute color mapping of pixels
    assert (x2-x1) == 4
    assert (y2-y1) == 8
    global tile_conter
    used_colors = set()
    for y in range(y1, y2):
        for x in range(x1, x2):
            color = surface.get_at((x, y))
            r,g,b,a = color
            used_colors.add((r,g,b,a))

    used_colors_without_shared = set(used_colors)
    if SHARED_COLOR11 in used_colors_without_shared:
        used_colors_without_shared.remove(SHARED_COLOR11)
    if SHARED_COLOR10 in used_colors_without_shared:
        used_colors_without_shared.remove(SHARED_COLOR10)
    other_colors = list(used_colors_without_shared)
    if len(other_colors) > 2:
        print("Warning: More than two (non shared) colors used")
        print("in tile (",x1,",",y1,")-(",x2,",",y2,")")
        print("Colors:", other_colors)
    color_mapping = {SHARED_COLOR11:"11", SHARED_COLOR10:"10"}
    if len(other_colors)==2:
        color_mapping.update({other_colors[0]:"00"})
        color_mapping.update({other_colors[1]:"01"})
    elif len(other_colors)==1:
        color_mapping.update({other_colors[0]:"00"})

    # now compute pixel data
    pixel_data = ";"+str(tile_conter)+"\n" # assembly comment to find tiles
    tile_conter+=1
    for y in range(y1, y2):
        pixel_data += ".BYTE %"
        for x in range(x1, x2):
            color = surface.get_at((x, y))
            r,g,b,a = color
            pixel_data += color_mapping[(r,g,b,a)]
        pixel_data += "\n"

    # now compute color data
    # e.g looks like '$2E'
    color_data = "$"
    if len(other_colors) == 2:
        value0 = format(COLOR_MAP[other_colors[0]], '1x')
        value1 = format(COLOR_MAP[other_colors[1]], '1x')
        
    elif len(other_colors) == 1:
        value0 = format(COLOR_MAP[other_colors[0]], '1x')
        value1 = format(COLOR_MAP[SHARED_COLOR11], '1x')  # default
        color_data += value0
    else:
        assert len(other_colors)==0
        value0 = format(COLOR_MAP[SHARED_COLOR10], '1x')  # default
        value1 = format(COLOR_MAP[SHARED_COLOR11], '1x')  # default
    color_data = "$"+value1+value0 


    return pixel_data, color_data

color_list = []
for j in range(width//8):
    color_row = []
    for i in range(width//4):
        pixel_data, color_data = compute_pixels_and_color(i*4,i*4+4,j*8,j*8+8)
        color_row.append(color_data)
        print(pixel_data)
        color_row.append(color_data)
    color_list.append(color_row)

# print color data
for color_row in color_list:
    color_data = ".BYTE "
    for cd in color_row[:-1]:
        color_data += cd+","
    color_data+= color_row[-1]
    print(color_data)

