# Cody BASIC Game

CodyRaid:
A Game for the [Cody Computer](https://www.codycomputer.org/).

# Run (Emulation)
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines codybasic.bin --uart1-source codyraid.bas --fast`

`LOAD 1,0` followed by `RUN` 

# Run (Real Hardware)

Run the program on the Cody computer using the Prop Plug. Use a terminal application such as RealTerm and insert delays so the Cody BASIC parser can keep up — for example, about 100 ms per line.

`LOAD 1,0` followed by `RUN` 

# How to Play
- Movement: WASD / Joystick UP/LEFT/RIGHT/DOWN
- FIRE: E / Fire Button
- Quit: Q

# Screenshot
![codyraid.png](codyraid.png)

# TODO:
- Hit detection
- Sprite movement
