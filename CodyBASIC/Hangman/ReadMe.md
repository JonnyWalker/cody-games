# Cody BASIC Game

Hangman:
A Game for the [Cody Computer](https://www.codycomputer.org/).

# Run (Emulation)
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines codybasic.bin --uart1-source hangman.bas`

`LOAD 1,0` followed by `RUN` 

# Run (Real Hardware)

Run the program on the Cody computer using the Prop Plug. Use a terminal application such as RealTerm and insert delays so the Cody BASIC parser can keep up — for example, about 100 ms per line.

`LOAD 1,0` followed by `RUN` 

# How to Play
- Start: CODY Key
- Play: Enter Letters
- END: ARROW Key

# Screenshot
![hangman.png](hangman.png)

# TODO:
- The string conc of wrong letters is hacky 
