Run using https://github.com/iTitus/cody_emulator :
cargo run --release -- --fix-newlines --uart1-source hangman.bas codybasic.bin

Run using the cody computer and the prop plug :
Use a program like realterm and add delays so the cody basic parser can catch up.
E.g. 100 msec per line

Known Bugs:
The wrong letter is shown an iteration to late
The string conc of wrong letters is hacky 
