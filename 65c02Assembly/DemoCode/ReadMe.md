# Cody 65c02 Assembly Tutorial

# Assemble and Run 

`64tass --mw65c02 --nostart -o 01_bordercolor.bin 01_bordercolor.asm` 

`cargo run --release -- --as-cartridge ../cody-games/65c02Assembly/DemoCode/01_bordercolor.bin` 

# 01 Border Color
- Example: Sets border color to red (01_bordercolor.asm)
- Task: change the color to blue (01_solution.asm)

# 02 Tile Color
- Example: Change 40 tile colors to cyan (02_tilecolor.asm)
- Task: draw 20 purple and 20 green tile below the cyan tiles (02_solution.asm)