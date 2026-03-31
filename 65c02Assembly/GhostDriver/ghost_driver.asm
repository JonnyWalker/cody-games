; 64tass --mw65c02 --nostart -o program.bin program.asm
START_ADDRESS      = $0300               ; The actual loading address of the program

VIA_BASE  = $9F00               ; VIA base address and register locations
VIA_IORB  = VIA_BASE+$0
VIA_IORA  = VIA_BASE+$1
VIA_DDRB  = VIA_BASE+$2
VIA_DDRA  = VIA_BASE+$3
VIA_T1CL  = VIA_BASE+$4
VIA_T1CH  = VIA_BASE+$5
VIA_SR    = VIA_BASE+$A
VIA_ACR   = VIA_BASE+$B
VIA_PCR   = VIA_BASE+$C
VIA_IFR   = VIA_BASE+$D
VIA_IER   = VIA_BASE+$E

VID_BLNK  = $D000               ; Video blanking status register
VID_CNTL  = $D001               ; Video control register
VID_COLR  = $D002               ; Video color register
VID_BPTR  = $D003               ; Video base pointer register
VID_SCRL  = $D004               ; Video scroll register
VID_SCRC  = $D005               ; Video screen common colors register
VID_SPRC  = $D006               ; Video sprite control register
SID_BASE  = $D400               ; SID registers (mostly for voice 1)

SID_V1FL  = SID_BASE+0
SID_V1FH  = SID_BASE+1
SID_V1PL  = SID_BASE+2
SID_V1PH  = SID_BASE+3
SID_V1CT  = SID_BASE+4
SID_V1AD  = SID_BASE+5
SID_V1SR  = SID_BASE+6
SID_FVOL  = SID_BASE+24

COLOR_BLACK       = 0
COLOR_WHITE       = 1
COLOR_RED         = 2
COLOR_CYAN        = 3
COLOR_PURPLE      = 4
COLOR_GREEN       = 5
COLOR_BLUE        = 6
COLOR_YELLOW      = 7
COLOR_ORANGE      = 8
COLOR_BROWN       = 9
COLOR_LIGHT_RED   = 10
COLOR_DARK_GRAY   = 11
COLOR_GRAY        = 12
COLOR_LIGHT_GREEN = 13
COLOR_LIGHT_BLUE  = 14
COLOR_LIGHT_GRAY  = 15

COLOR_BYTE .sfunction first, second, (first * 16 + second)

TEMP      = $D0
EXPLOSION_X = $D1
EXPLOSION_Y = $D2
MAP_POINTER = $D4               ; 2 byte pointer
SCREEN_POINTER = $D6            ; 2 byte pointer
GAME_IS_RUNNING = $D8           ; flag
SCORE = $D9                     ; 2 byte counter
TIMER = $DB                     ; Counter
ENEMY_TIMERS = $E0              ; 5 counters for each enemy
SFX_TIMER = $E5                 ; Counter for sound effects

; Program header for Cody Basic's loader (needs to be first)

.WORD START_ADDRESS                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (START_ADDRESS + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program goes below here

.LOGICAL    START_ADDRESS                ; The actual program gets loaded at START_ADDRESS

; Lanes:
; Each lane is 14 pixels wide with one pixel in between
; 1: [$35, $43]
; 1.5: $44
; 2: [$45, $53]
; 2.5: $54
; 3: [$55, $63]
; 3.5: $64
; 4: [$65, $73]
; 4.5: $74
; 5: [$75, $83]

SPRITE_X .sfunction index, base_address=$D080, base_address + (4 * index)
SPRITE_Y .sfunction index, base_address=$D080, base_address + 1 + (4 * index)
SPRITE_COLOR .sfunction index, base_address=$D080, base_address + 2 + (4 * index)
SPRITE_IMAGE .sfunction index, base_address=$D080, base_address + 3 + (4 * index)

SET_SPRITE .macro sprite_number, x_position, y_position, color_1, color_2, image_index, base_address=$D080
    LDA \x_position
    STA SPRITE_X(\sprite_number, \base_address)
    LDA \y_position
    STA SPRITE_Y(\sprite_number, \base_address)
    LDA #COLOR_BYTE(\color_1, \color_2)
    STA SPRITE_COLOR(\sprite_number, \base_address)
    LDA #(\image_index)
    STA SPRITE_IMAGE(\sprite_number, \base_address)
    .endmacro

CHARACTER_MEMORY .sfunction x_position, y_position, base_address=$C400, base_address + ($28 * y_position + x_position)

PRINT .macro text, x_position, y_position, base_address=$C400
    .for i in range(len(\text))
    LDA #\text[i]
    STA CHARACTER_MEMORY(\x_position + i, \y_position)
    .endfor
    .endmacro

COLOR_OBSTACLE_0 = (COLOR_BLUE, COLOR_GREEN)
COLOR_OBSTACLE_1 = (COLOR_BLUE, COLOR_CYAN)
COLOR_OBSTACLE_2 = (COLOR_LIGHT_BLUE, COLOR_PURPLE)
COLOR_OBSTACLE_3 = (COLOR_BLUE, COLOR_BROWN)
COLOR_OBSTACLE_4 = (COLOR_LIGHT_BLUE, COLOR_DARK_GRAY)
OBSTACLE_COLORS = [COLOR_OBSTACLE_0, COLOR_OBSTACLE_1, COLOR_OBSTACLE_2, COLOR_OBSTACLE_3, COLOR_OBSTACLE_4]

MAIN
    LDA #1
    STA GAME_IS_RUNNING

    ; Set color memory to $D800 ($E) and border color to blue ($6)
    LDA #$E6
    STA $D002

    ; Set screen memory location to $C400 ($9) and character memory location
    ; to $C800 ($5)
    LDA #$95
    STA $D003

    ; Set character colors
    LDA #COLOR_BYTE(COLOR_BLACK, COLOR_WHITE)
    STA $D005

    ; Set sprite bank 0 and sprite common color black ($0)
    LDA #$00
    STA $D006

    ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)
    LDA #$07
    STA VIA_DDRA

    ; Set VIA to read joystick 1
    LDA #$06
    STA VIA_IORA

    ; Copy Sprite data
    LDX #0
MAIN_COPYSPRITE
    LDA SPRITEDATA, X
    STA $A000, X
    LDA SPRITEDATA+$100, X
    STA $A100, X
    INX
    CPX #255
    BNE MAIN_COPYSPRITE

    JSR SET_SCREEN_MEMORY
    JSR SET_CHARS
    JSR SET_COLOR

    ; Setup sprite for player
    #SET_SPRITE 0, #$56, #$8E, COLOR_BLUE, COLOR_RED, 1

    ; Setup sprite for obstacles
    .for i in range(5)
    #SET_SPRITE i + 1, #($36 + i * 16), #$F0, OBSTACLE_COLORS[i][0], OBSTACLE_COLORS[i][1], 2
    LDA #(120 + 30 * i)
    STA ENEMY_TIMERS + i
    .endfor

    JSR SETUP_HUD
    STZ SCORE
    STZ SCORE+1
    JSR HANDLE_SCORE_PRINT

MAIN_LOOP
    LDA GAME_IS_RUNNING
    BEQ MAIN_GAME_OVER_SCREEN
    ; Game loop
    JSR HANDLE_INPUT
    JSR MOVE_OBSTACLES
    JSR HANDLE_SCORE
    JSR CHECK_COLLISION
    JSR WAITBLANK
    BRA MAIN_LOOP
MAIN_GAME_OVER_SCREEN
    ; Game over loop
    JSR WAIT_FOR_RESTART
    JMP MAIN
    BRA MAIN_LOOP
    ; End loop (failsafe)
END
    BRA END

WAIT_FOR_RESTART
    #PRINT "GAME OVER", 0, 7
    #PRINT "Press fire", 0, 9
    #PRINT "button to", 0, 10
    #PRINT "restart", 0, 11
WAIT_FOR_RESTART_LOOP
    LDA VIA_IORA
    LSR A
    LSR A
    LSR A
    BIT #16
    BNE WAIT_FOR_RESTART_LOOP
    LDA #1
    STA GAME_IS_RUNNING
    RTS


PLAY_EXPLOSION
    STZ SFX_TIMER
    .bfor i in range(5)
    LDX #20
    #SET_SPRITE 6, EXPLOSION_X, EXPLOSION_Y, i < 3 ? COLOR_YELLOW : COLOR_DARK_GRAY, COLOR_RED, 3+i
PLAY_EXPLOSION_LOOP
    JSR PLAY_SFX_EXPLOSION
    JSR WAITBLANK
    DEX
    BNE PLAY_EXPLOSION_LOOP
    .endfor
    #SET_SPRITE 6, 0, 0, COLOR_DARK_GRAY, COLOR_RED, 0
    RTS

PLAY_SFX_EXPLOSION
    LDA SFX_TIMER
    BEQ PLAY_SFX_EXPLOSION_START
    CMP #60
    BNE PLAY_SFX_EXPLOSION_END
    ; Mute sound
    LDA #0
    STA SID_V1CT
    BRA PLAY_SFX_EXPLOSION_END
PLAY_SFX_EXPLOSION_START
    ; Advance sound for one frame
    LDA #$0F            ; Set main volume
    STA SID_FVOL

    LDA #<2400          ; Set starting frequency
    STA SID_V1FL
    LDA #>2400
    STA SID_V1FH

    LDA #$50            ; Attack/decay
    STA SID_V1AD

    LDA #$F0            ; Sustain/release
    STA SID_V1SR

    LDA #$81            ; Begin playing
    STA SID_V1CT
PLAY_SFX_EXPLOSION_END
    INC SFX_TIMER
    RTS


SETUP_HUD
    #PRINT "SCORE", 2, 4
    RTS

CHECK_COLLISION
    .bfor i in range(5)
    ; Check x position
    ; Check if sprite is too far left
    CLC
    LDA SPRITE_X(0)
    SBC SPRITE_X(1+i)  ; player_x - enemy_x
    CMP #9
    BPL CHECK_COLLISION_NEXT
    ; Check if sprite is too far right
    CLC
    LDA SPRITE_X(i+1)
    SBC SPRITE_X(0)  ; enemy_x - player_x
    CMP #9
    BPL CHECK_COLLISION_NEXT
    ; Check y position
    ; Check if sprite is too far down
    CLC
    LDA SPRITE_Y(0)
    SBC SPRITE_Y(1+i)  ; player_y - enemy_y
    CMP #19
    BPL CHECK_COLLISION_NEXT
    ; Check if sprite is too far up
    CLC
    LDA SPRITE_Y(i+1)
    SBC SPRITE_Y(0)  ; enemy_y - player_y
    CMP #19
    BPL CHECK_COLLISION_NEXT
    JMP CHECK_COLLISION_EXPLOSION
CHECK_COLLISION_NEXT
    .endfor
    RTS
CHECK_COLLISION_EXPLOSION
    LDA SPRITE_X(0)
    STA EXPLOSION_X
    LDA SPRITE_Y(0)
    STA EXPLOSION_Y
    JSR PLAY_EXPLOSION
    STZ GAME_IS_RUNNING
    RTS

HANDLE_SCORE
    ; Increase the timer
    INC TIMER
    ; If the timer has reached its limit, we increase the score
    LDA TIMER
    CMP #25
    BNE HANDLE_SCORE_SKIP_SCORE
    ; Reset timer
    STZ TIMER
    ; Increase score as decimal number
    INC SCORE
HANDLE_SCORE_PRINT
    ; Check the low nibble of the low byte. If it is not $A, we are done
    LDA #$0F
    AND SCORE
    CMP #$0A
    BNE HANDLE_SCORE_SKIP_INC
    ; Add 6 to the low byte and then check the high nibble.
    CLC
    LDA #6
    ADC SCORE
    STA SCORE
    LDA #$F0
    AND SCORE
    CMP #$A0
    BNE HANDLE_SCORE_SKIP_INC
    ; Repeat the same for the high byte
    STZ SCORE
    INC SCORE+1
    ; Check the low nibble of the low byte. If it is not $A, we are done
    LDA #$0F
    AND SCORE+1
    CMP #$0A
    BNE HANDLE_SCORE_SKIP_INC
    ; Add 6 to the low byte and then check the high nibble.
    CLC
    LDA #6
    ADC SCORE+1
    STA SCORE+1
    LDA #$F0
    AND SCORE+1
    CMP #$A0
    BNE HANDLE_SCORE_SKIP_INC
    STZ SCORE+1
HANDLE_SCORE_SKIP_INC
    ; Display the score
    LDA #$0F
    AND SCORE
    JSR A_TO_CHAR_LOW_NIBBLE
    STA $C400 + ($28*5 + 6)
    LDA #$F0
    AND SCORE
    JSR A_TO_CHAR_HIGH_NIBBLE
    STA $C400 + ($28*5 + 5)
    LDA #$0F
    AND SCORE+1
    JSR A_TO_CHAR_LOW_NIBBLE
    STA $C400 + ($28*5 + 4)
    LDA #$F0
    AND SCORE+1
    JSR A_TO_CHAR_HIGH_NIBBLE
    STA $C400 + ($28*5 + 3)
HANDLE_SCORE_SKIP_SCORE
    RTS

A_TO_CHAR_LOW_NIBBLE
    CLC
    CMP #10
    BPL A_TO_CHAR_LOW_NIBBLE_HEX_DIGIT
    ADC #'0'
    RTS
A_TO_CHAR_LOW_NIBBLE_HEX_DIGIT
    ADC #('A'-11)
    RTS

A_TO_CHAR_HIGH_NIBBLE
    LSR A
    LSR A
    LSR A
    LSR A
    JSR A_TO_CHAR_LOW_NIBBLE
    RTS


HANDLE_INPUT
    LDX #0
    LDY #0
    ; Read joystick
    LDA VIA_IORA
    LSR A
    LSR A
    LSR A
    ; Joystick right?
    BIT #8
    BNE HANDLE_INPUT_CHECK_LEFT
    LDX #1
    BRA HANDLE_INPUT_CHECK_DOWN
HANDLE_INPUT_CHECK_LEFT
    ; Joystick left?
    BIT #4
    BNE HANDLE_INPUT_CHECK_DOWN
    LDX #$FF
HANDLE_INPUT_CHECK_DOWN
    ; Joystick down?
    BIT #2
    BNE HANDLE_INPUT_CHECK_UP
    LDY #1
    BRA HANDLE_INPUT_CALL
HANDLE_INPUT_CHECK_UP
    ; Joystick up?
    BIT #1
    BNE HANDLE_INPUT_CALL
    LDY #$FF
    BRA HANDLE_INPUT_CALL
HANDLE_INPUT_CALL
    JSR MOVE_PLAYER
    RTS

; Move functions
MOVE_PLAYER
    ; Move X
    CLC
    STX TEMP
    LDA SPRITE_X(0)
    ADC TEMP
    ; Limit X position
    CMP #$35
    BPL MOVE_PLAYER_CHECK_END_X
    LDA #$35
    BRA MOVE_PLAYER_STORE_X
MOVE_PLAYER_CHECK_END_X
    CMP #$79
    BMI MOVE_PLAYER_STORE_X
    LDA #$78
MOVE_PLAYER_STORE_X
    STA SPRITE_X(0)
    ; Move Y
    CLC
    STY TEMP
    LDA SPRITE_Y(0)
    ADC TEMP
    ; Limit Y position
    CMP #20
    BNE MOVE_PLAYER_CHECK_END_Y
    LDA #21
    BRA MOVE_PLAYER_STORE_Y
MOVE_PLAYER_CHECK_END_Y
    CMP #201
    BNE MOVE_PLAYER_STORE_Y
    LDA #200
MOVE_PLAYER_STORE_Y
    STA SPRITE_Y(0)
    RTS

SET_SCREEN_MEMORY
    LDX #25
    ; Store $C400 in SCREEN_POINTER
    STZ SCREEN_POINTER
    LDA #$C4
    STA SCREEN_POINTER+1
    ; Store MAPDATA in MAP_POINTER
SET_SCREEN_MEMORY_ROW
    LDY #40
    LDA #<MAPDATA
    STA MAP_POINTER
    LDA #>MAPDATA
    STA MAP_POINTER+1
SET_SCREEN_MEMORY_COL
    LDA (MAP_POINTER)
    STA (SCREEN_POINTER)
    ; Increase MAP_POINTER by one
    INC MAP_POINTER
    BNE SET_SCREEN_MEMORY_INC_SCREEN_POINTER
    INC MAP_POINTER+1
SET_SCREEN_MEMORY_INC_SCREEN_POINTER
    ; Increase SCREEN_POINTER by one
    INC SCREEN_POINTER
    BNE SET_SCREEN_MEMORY_POST_ADD
    INC SCREEN_POINTER+1
SET_SCREEN_MEMORY_POST_ADD
    ; Count down Y
    DEY
    BNE SET_SCREEN_MEMORY_COL
    ; Count down X
    DEX
    BNE SET_SCREEN_MEMORY_ROW
    RTS

SET_CHARS
    ; Copy ASCII characters
    LDX #0
SET_CHARS_LOOP_ASCII
    ; We have $300 characters ($20-$80)
    LDA ASCIIDATA, X
    STA $C900, X
    LDA ASCIIDATA + $100, X
    STA $CA00, X
    LDA ASCIIDATA + $200, X
    STA $CB00, X
    INX
    BNE SET_CHARS_LOOP_ASCII
    ; Copy custom characters
    LDX #0
SET_CHARS_LOOP
    LDA CHARDATA, X
    STA $C800, X
    INX
    BNE SET_CHARS_LOOP
    RTS

SET_COLOR
    LDA #COLOR_BYTE(COLOR_GREEN, COLOR_LIGHT_GRAY)
    LDX #0
SET_COLOR_LOOP
    STA $D800, X
    STA $D900, X
    STA $DA00, X
    STA $DB00, X
    INX
    BNE SET_COLOR_LOOP
    RTS

MOVE_OBSTACLES
    .bfor i in range(5)
    ; Check timers
    LDA ENEMY_TIMERS + i
    ; If the counter has reached zero, we start moving down
    BEQ MOVE_OBSTACLES_MOVE
    ; Count down timer
    DEC ENEMY_TIMERS + i
    BRA MOVE_OBSTACLES_NEXT
MOVE_OBSTACLES_MOVE
    ; Move down
    LDA #(i == 1 || i == 3 ? 1 : (i == 2 ? 2 : 3))  ; TODO randomize speed on each reset
    CLC
    ADC SPRITE_Y(i + 1)
    STA SPRITE_Y(i + 1)
    ; If we reach the end, set the timer to a random delay
    BCC MOVE_OBSTACLES_NEXT
    STZ SPRITE_Y(i + 1)
    ; Set time
    LDA #(3*i + 6)
    STA ENEMY_TIMERS + i
MOVE_OBSTACLES_NEXT
    .endfor
    RTS

WAITBLANK
_WAITVIS
    ; Wait until the blanking is zero (drawing the screen)
    LDA VID_BLNK
    BNE _WAITVIS
_WAITBLANK
    ; Wait until the blanking is one (not drawing the screen)
    LDA VID_BLNK
    BEQ _WAITBLANK
    RTS

MAPDATA
.BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 2, 1, 2, 3, 2, 1, 2, 3, 2, 1, 2, 3, 2, 1, 2, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

CHARDATA
; Blank tile
.BYTE %11_11_11_11
.BYTE %11_11_11_11
.BYTE %11_11_11_11
.BYTE %11_11_11_11
.BYTE %11_11_11_11
.BYTE %11_11_11_11
.BYTE %11_11_11_11
.BYTE %11_11_11_11
; Street left (col 0)
.BYTE %11_00_00_00
.BYTE %11_00_00_00
.BYTE %11_00_00_00
.BYTE %11_00_00_00
.BYTE %11_00_00_00
.BYTE %11_00_00_00
.BYTE %11_00_00_00
.BYTE %11_00_00_00
; Street clear (col 1 and 3)
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
; Street middle (col 2)
.BYTE %10_00_00_00
.BYTE %10_00_00_00
.BYTE %10_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
.BYTE %00_00_00_00
; Testsprite
.BYTE %11_11_01_01
.BYTE %11_11_01_01
.BYTE %11_11_01_01
.BYTE %11_11_01_01
.BYTE %10_10_00_00
.BYTE %10_10_00_00
.BYTE %10_10_00_00
.BYTE %10_10_00_00

ASCIIDATA
.include "charset.asm"

SPRITEDATA
; Empty sprite
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00
.include "cars.asm"
.include "explosion.asm"

LAST                              ; End of the entire program


.ENDLOGICAL