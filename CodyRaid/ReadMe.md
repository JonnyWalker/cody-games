# Cody Game

CodyRaid:
A Game for the [Cody Computer](https://www.codycomputer.org/).

# Run
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines --uart1-source codyraid.bas codybasic.bin`

Run using the cody computer and the prop plug :
Use a program like RealTerm and add delays so the cody basic parser can catch up.
E.g. 100 msec per line

# How to Play
- Movement: WASD
- Quit: Q

# Screenshot
![codyraid.png](codyraid.png)

# TODO:
- Joystick
- Fire 
- Hit detection
- Sprite movement
