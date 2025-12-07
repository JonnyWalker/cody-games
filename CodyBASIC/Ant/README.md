# CodysAnt

A game written in Cody BASIC for the [Cody Computer](https://www.codycomputer.org/).

This is a No Player Game, meaning no input from the player is required apart from the initial game rule.
The rule consists of a string of any length made up of the characters “L, R, F”.
The game works like this: [Langton’s ant](https://en.wikipedia.org/wiki/Langton%27s_ant)



# How to Play
Interesting rules:

- LLRRRLRLRLLR – produces a triangle
- LLRR – symmetrical
- RLR – chaos
- RL – vanilla

# Screenshot

# Run (Emulation)
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines codybasic.bin --uart1-source ant.bas`

`LOAD 1,0` followed by `RUN` 

# Run (Real Hardware)

Run the program on the Cody computer using the Prop Plug. Use a terminal application such as RealTerm and insert delays so the Cody BASIC parser can keep up — for example, about 100 ms per line.

`LOAD 1,0` followed by `RUN` 
