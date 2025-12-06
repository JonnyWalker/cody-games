# Cody Game

A Wordle clone written in Cody BASIC.
A Game for the [Cody Computer](https://www.codycomputer.org/).

You have to guess a 5-letter word and have 5 attempts to do so.
Letters that are in the correct position are highlighted in green. Letters that are in the word but not in the correct position are highlighted in yellow. Letters that are not in the word remain gray.
Press the Cody button to start the game. This stops an internal timer, which is used to select a random word.

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
- END: CODY Key

# Screenshot
![wordle.png](wordle.png)