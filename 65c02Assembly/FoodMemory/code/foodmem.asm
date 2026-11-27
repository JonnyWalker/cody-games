; 64tass --mw65c02 --nostart -o foodmem.bin foodmem.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < foodmem.bin
; plink -batch -serial "/dev/ttyUSB0" -sercfg "19200,8,1,n,N" < foodmem.bin
.include "codyconstants.asm"

; MARK: - ZP Variables
MEMSPTR   = $20       ; The source pointer for memory-related utility routines (2 bytes)
MEMDPTR   = $22       ; The destination pointer for memory-related utility routines (2 bytes)
MEMSIZE   = $24       ; The size of memory to move for memory-related utility routines (2 bytes)

LAST_RANDOM_VALUE     = $D0   ; 8-Bit: last used random value
TILE_COUNTER          = $D1   ; 0-15: used to iterate over tiles in test draw
SCREEN_PTR            = $D2   ; 16-Bit variable
COLOR_MEM_PTR16       = $D4   ; 16-Bit variable. used to write color data to memory
CARD_INDEX            = $D6   ; 0-5: used to check if one row of card tiles has been drawn
CHAR_ROM_PTR16        = $DB   ; 16-Bit variable. used to read tile char data from ROM
CHAR_MEM_PTR16        = $DD   ; 16-Bit variable. used to write tile char data to memory
COLOR_ROM_PTR         = $DF   ; 16-Bit variable. used to read tile color data from ROM
FRAME_CTR16           = $E1   ; 16-Bit variable. frame counter
MOVEMENT_COOLDOWN_CTR = $E3   ; 8-Bit variable. used to slowdown movement
CARD_PTR16            = $E4

; CONSTANTS
CARDS_EACH_ROW = #$06
MOVEMENT_COOLDOWN = #10    ; how many frames between each movement action
SCRRAM    = $A000               ; Screen memory location
COLRAM    = $D800               ; Color memory location

; Program header for Cody Basic's loader (needs to be first)
.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.
.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

; print text of length at (row, column)
PRINT .macro text, column, row, length
    LDX #0
 _Print_Text
    LDA \text, X
    STA 50176+\column+\row*40, X ; 50176=$C400, 40 characters each row
    INX
    CPX #\length
    BNE _Print_Text
    .endmacro

MAIN                    ; The program starts running from here
    LDA #$E0            ; Set border color (Bits 0-3) to black=0
                        ; and set color memory to $D800 (A000+14*1024=D800), E=14
    STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
    LDA #$01            ; Store shared colors (black=0 and white=1)
    STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

    LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)
    STA VIA_DDRA        ; This is required for keyboard input

    JSR INIT_RANDOM

SHOW_TITLE_SCREEN
    STZ FRAME_CTR16+0         ; FRAME_CTR16=0
    STZ FRAME_CTR16+1
    STZ MOVEMENT_COOLDOWN_CTR ; MOVEMENT_COOLDOWN_CTR=0
    STZ CARD_PTR16+0
    STZ CARD_PTR16+1

    STZ SPR0_X          ; Hide cursor during title screen by setting sprite pos to (0,0)
    STZ SPR0_Y
    JSR SHOW_TITLE
    JSR CODYSID_LOCAL_MAIN

_WAIT_FOR_SPACE
    ; exit loop on space key
    JSR KEY_TO_A
    CMP #$20
    BNE _WAIT_FOR_SPACE

    ; disbale bitmap mode
    JSR WAITBLANK       ; Wait for the next frame
    LDA #$00
    STA VID_CNTL
    LDA #$95            ; Set character memory to $C800 (A000+5*2048=C800)
                        ; and set screen memory location $C400 (A000+9*1024=C400)
    STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)
    JSR INIT_SPRITES

    ; clear with white=1 and black=0
    LDA #$10
    ; replace all characters with empty character
    JSR CLEAR_SCREEN
    ; compute random card positions
    JSR COMPUTE_RANDOM_LEVEL
    ; compute random card images
    JSR COMPUTE_RANDOM_TILE_SET
    ; load tile set from game ROM to memory
    JSR COPY_ALL_CHAR_TO_MEMORY
    ; draw open cards (only a debug subroutine)
    JSR TEST_DRAW
    ; Show cursor
    LDA #12+8           ; sprite X
    STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
    LDA #21+25          ; sprite Y
    STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)
    STZ CARD_PTR16+0    ; Keep CARD_PTR16 in sync with cursor pos
    STZ CARD_PTR16+1

_GAME_LOOP
    JSR WAITBLANK       ; Wait for the next frame

    INC FRAME_CTR16+0       ; FRAME_CTR16++
    BNE _FRAME_CTR_INC_DONE ; If the lower half of the frame counter is zero we had an overflow and...
    INC FRAME_CTR16+1       ; ...we also have to increment the upper half
_FRAME_CTR_INC_DONE
    JSR KEY_TO_A        ; A = pressed key
    JSR EVAL_KEYBOARD
    JSR KEY_TO_A        ; A = pressed key   
    CMP #"R"
    BEQ _NEW_GAME
    JMP _GAME_LOOP
_NEW_GAME
    JMP SHOW_TITLE_SCREEN 
    

; MARK: Init

.include "init_game.asm"

; MARK: Drawing

.include "graphics.asm"
.include "draw_cards.asm"
.include "title_screen.asm"

; MARK: Music

.include "codysid_local.asm"

; MARK: I/0

.include "key_input.asm"
.include "input.asm"

; MARK: Utilities

.include "math.asm"
.include "random.asm"

; MARK: Data Segment

.include "tile_set0.asm"
.include "tile_set1.asm"
.include "tile_set2.asm"
.include "tile_set3.asm"
.include "sprites.asm"

; TODO: fix naming (missing underscore)
MEMORY_SETS_PIXELS
    .WORD TILE_SET0
    .WORD TILE_SET1
    .WORD TILE_SET2
    .WORD TILE_SET3

MEMORY_SETS_COLORS
    .WORD COLOR_DATA0
    .WORD COLOR_DATA1
    .WORD COLOR_DATA2
    .WORD COLOR_DATA3

LEVEL
    .BYTE 0,0,0,0,0,0  ; level data.
    .BYTE 0,0,0,0,0,0  ;
    .BYTE 0,0,0,0,0,0  ; 0 if no card assigned,
    .BYTE 0,0,0,0,0,0  ; value 1...12 otherwise.

; End of the entire program
LAST
.ENDLOGICAL
