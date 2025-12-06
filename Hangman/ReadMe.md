# Cody Game

Hangman:
A Game for the [Cody Computer](https://www.codycomputer.org/).

# Run (Emulation)
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines codybasic.bin --uart1-source hangman.bas`

`LOAD 1,0` followed by `RUN` 

# Run (Real Hardware)

Run using the cody computer and the prop plug :
Use a program like RealTerm and add delays so the cody basic parser can catch up.
E.g. 100 msec per line

`LOAD 1,0` followed by `RUN` 

# How to Play
- Start: CODY Key
- Play: Enter Letters
- END: ARROW Key

# Screenshot
![hangman.png](hangman.png)

# TODO:
- The string conc of wrong letters is hacky 
