# Cody 65c02 Assembly Tutorial

# Assemble and Run 

`64tass --mw65c02 --nostart -o 01_bordercolor.bin 01_bordercolor.asm` 

`cargo run --release -- --as-cartridge ../cody-games/65c02Assembly/DemoCode/01_bordercolor.bin` 

# 01 Border Color
- Example: sets border color to red (01_bordercolor.asm)
- Task: change the color to blue (01_solution.asm)

# 02 Tile Color
- Example: change 40 tile colors to cyan (02_tilecolor.asm)
- Task: draw 20 purple and 20 green tile below the cyan tiles (02_solution.asm)

# 03 Tile Data
- Example: changes 20 tiles in the first row (03_tiledata.asm)
- Task: draw 20 tiles of type one in the middel row of the screen by starting at tile 490 (03_solution.asm)
