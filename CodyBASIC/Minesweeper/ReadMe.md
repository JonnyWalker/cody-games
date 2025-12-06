# Minesweeper

A Cody BASIC Game for the [Cody Computer](https://www.codycomputer.org/).


# How to Play
Controls:

- Move selection with WASD
- Place/remove flag with SPACE
- Reveal with ARROW

The game ends when you lose.

# Screenshot
![minesweeper.png](minesweeper.png)

# Run (Emulation)
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines codybasic.bin --uart1-source minesweeper.bas`

`LOAD 1,0` followed by `RUN` 

# Run (Real Hardware)

Run the program on the Cody computer using the Prop Plug. Use a terminal application such as RealTerm and insert delays so the Cody BASIC parser can keep up — for example, about 100 ms per line.

`LOAD 1,0` followed by `RUN` 

# TODO
Improved graphics

Safe space at the beginning