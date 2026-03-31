# Cody Synthesizer

A Cody BASIC Game for the [Cody Computer](https://www.codycomputer.org/).

# How to Play
A software synthesizer written in Cody BASIC.
The program transforms the upper two key rows of the keyboard into a
playable piano layout and provides real-time waveform selection and ADSR
envelope control.

## Overview

This project implements a monophonic synthesizer using the system's
sound hardware registers. The keyboard layout is mapped to resemble a
piano:

-   Second upper row → White keys
-   Top row → Black keys
-   Key D corresponds to C5
-   Default waveform: Triangle
## Waveform Selection

Waveforms can be changed during runtime:

Z = Triangle
X = Sawtooth
C = Square
V = Noise

The selected waveform directly modifies the oscillator control register.

## ADSR Envelope Control

Envelope parameters can be adjusted dynamically:

B = Attack
N = Decay
M = Sustain
Square = Release

-   Each parameter cycles through values 1--15.
-   When exceeding 15, the value wraps back to 1.

## Current Limitation

The ADSR implementation increments continuously while a key is held
down.
Since the main loop executes rapidly, holding a key results in very fast
parameter changes, making precise adjustment difficult.

## Implementation Notes

-   Direct hardware register access via POKE for oscillator and envelope control
-   ADSR values are written to the corresponding envelope registers
-   The main loop polls keyboard input and updates sound registers in real time

## Potential Improvements

-   Debounced key handling (increase value only once per key press)
-   Shift + Key combination to decrease parameter values
-   Joystick-based ADSR adjustment
-   On-screen display showing:
    -   Current waveform
    -   Attack value
    -   Decay value
    -   Sustain value
    -   Release value

# Screenshot
TODO
# Author

Colin Lau

# Run (Emulation)
Run using  [Cody Computer Emulator](https://github.com/iTitus/cody_emulator):
`cargo run --release -- --fix-newlines codybasic.bin --uart1-source Cody_Synth.bas`

`LOAD 1,0` followed by `RUN` 

# Run (Real Hardware)

Run the program on the Cody computer using the Prop Plug. Use a terminal application such as RealTerm and insert delays so the Cody BASIC parser can keep up — for example, about 100 ms per line.

`LOAD 1,0` followed by `RUN` 

