; 64tass --mw65c02 --nostart -o foodmem.bin foodmem.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < foodmem.bin
; plink -batch -serial "/dev/ttyUSB0" -sercfg "19200,8,1,n,N" < foodmem.bin
.include "codyconstants.asm"

; MARK: - ZP Variables
RANDOM_VALUE          = $D0   ; TODO: remove
TILE_COUNTER          = $D1   ; 0-15: used to iterate over tiles in test draw
SCREEN_PTR            = $D2   ; 16-Bit variable
COLOR_MEM_PTR16       = $D4   ; 16-Bit variable. used to write color data to memory
CARD_INDEX            = $D6   ; 0-5: used to check if one row of card tiles has been drawn
CHAR_ROM_PTR16        = $DB   ; 16-Bit variable. used to read tile char data from ROM
CHAR_MEM_PTR16        = $DD   ; 16-Bit variable. used to write tile char data to memory
COLOR_ROM_PTR         = $DF   ; 16-Bit variable. used to read tile color data from ROM
FRAME_CTR             = $E1   ; 8-Bit variable. frame counter
MOVEMENT_COOLDOWN_CTR = $E2   ; 8-Bit variable. used to slowdown movement
CARD_PTR16            = $E3

; CONSTANTS
CARDS_EACH_ROW = #$06
MOVEMENT_COOLDOWN = #10    ; how many frames between each movement action

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
    LDA #$E1            ; Set border color (Bits 0-3) to white=1
                        ; and set color memory to $D800 (A000+14*1024=D800), E=14
    STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
    LDA #$95            ; Set character memory to $C800 (A000+5*2048=C800)
                        ; and set screen memory location $C400 (A000+9*1024=C400)
    STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)
    LDA #$01            ; Store shared colors (black=0 and white=1)
    STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

    LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)
    STA VIA_DDRA        ; This is required for keyboard input

    LDX #0              ; Copy sprite data into video memory
_COPYSPRT   
    LDA SPRITEDATA,X
    STA $A400,X         ; sprite pixel data location. Page 327 and 535 
    INX
    CPX #64
    BNE _COPYSPRT

    LDA #$00            ; Sprite bank 0, white as common sprite color 
    STA VID_SPRC        ; VID_SPRC=$D006 (see codyconstants.asm)
    LDA #12+8           ; sprite X
    STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
    LDA #21+25          ; sprite Y
    STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)
    LDA #$11            ; white=1 color 1, white=1 color 2 
    STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
    LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
    STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)  

    STZ FRAME_CTR       ; FRAME_CTR=0
    STZ CARD_PTR16+0
    STZ CARD_PTR16+1



SHOW_TITLE_SCREEN
    ; overwrites all other graphics
    JSR LOAD_CODSCII_TO_CHAR_MEM

    LDA #$10            ; clear with white=1 and black=0
    JSR CLEAR_SCREEN    ; replace all characters with empty character

    #PRINT Text0, 0,  1, 11 ; prints "Food Memory"
    #PRINT Text1, 0, 23, 24 ; prints "PRESS SPACE TO CONTINUE."

  _WAIT_FOR_SPACE
    ; exit loop on space key
    JSR KEY_TO_A
    CMP #$20
  BNE _WAIT_FOR_SPACE

_NEW_GAME
    ; clear with white=1 and black=0
    LDA #$10
    ; replace all characters with empty character
    JSR CLEAR_SCREEN




INIT_RANDOM_LEVEL               ; idea: for all cards,
                                ; draw random index

    LDX #23
_zero
    STZ LEVEL,X
    DEX
    BPL _zero
                                ;
    LDY #25                     ; 24 iterations.
                                ; we start at 25 so that Y / 2
                                ; produces card values 12...1,
                                ; each exactly twice. if we
                                ; started at 24 we would produce one 0.
_loop                           ;
    JSR GET_RANDOM_BYTE_TO_A    ; get random byte, and convert to
    TAX                         ; index into level. mod 24 using
    LDA MOD_24,X                ; a lookup table.
    TAX                         ;
    LDA LEVEL,X                 ; check if card at that index is 0.
    BNE _loop                   ; if its not, then theres already a
                                ; card assigned; try again.
    TYA                         ;
    LSR                         ; div 2 to map 25...1 to 12...1
    STA LEVEL,X                 ; store card id at chosen index.
    DEY                         ;
    CPY #1                      ;
    BNE _loop                   ;

    ; randomly select one of
    ; 4 available memory sets
    JSR GET_RANDOM_BYTE_TO_A
    AND #3
    ASL
    TAX
    LDA MEMORY_SETS_PIXELS,X
    LDY MEMORY_SETS_COLORS,X
    STA CHAR_ROM_PTR16 + 0
    STY COLOR_ROM_PTR + 0
    INX
    LDA MEMORY_SETS_PIXELS,X
    LDY MEMORY_SETS_COLORS,X
    STA CHAR_ROM_PTR16 + 1
    STY COLOR_ROM_PTR + 1

    ; set pointer to character memory $C800
    LDA #$00
    STA CHAR_MEM_PTR16+0
    LDA #$C8
    STA CHAR_MEM_PTR16+1

    ; load tile set from game ROM to memory
    JSR COPY_ALL_CHAR_TO_MEMORY

    ; draw open cards (only a debug subroutine)
    JSR TEST_DRAW

_POLL_KEYBOARD
    JSR WAITBLANK       ; Wait for the next frame
    INC FRAME_CTR       ; FRAME_CTR++

    JSR KEY_TO_A        ; A = pressed key

    CMP #"R"
    BNE _CHECK_NEXT_KEY0
    JMP _NEW_GAME

_CHECK_NEXT_KEY0
    LDX MOVEMENT_COOLDOWN_CTR   ; if MOVEMENT_COOLDOWN_CTR == 0: check movement
    BEQ _MOVEMENT
    DEC MOVEMENT_COOLDOWN_CTR   ; else: MOVEMENT_COOLDOWN_CTR-- and check keys again next frame
    JMP _POLL_KEYBOARD
_MOVEMENT
    CMP #"W"
    BNE _CHECK_NEXT_MOVE_KEY0
    JMP _UP
_CHECK_NEXT_MOVE_KEY0
    CMP #"A"
    BNE _CHECK_NEXT_MOVE_KEY1
    JMP _LEFT
_CHECK_NEXT_MOVE_KEY1
    CMP #"D"
    BNE _CHECK_NEXT_MOVE_KEY2
    JMP _RIGHT
_CHECK_NEXT_MOVE_KEY2
    CMP #"S"
    BNE _CHECK_NEXT_MOVE_KEY3
    JMP _DOWN
_CHECK_NEXT_MOVE_KEY3
    JMP _POLL_KEYBOARD

_NEW_GAME
    JMP SHOW_TITLE_SCREEN

_SET_MOVEMENT_COOLDOWN
    LDA MOVEMENT_COOLDOWN       ; MOVEMENT_COOLDOWN_CTR = MOVEMENT_COOLDOWN
    STA MOVEMENT_COOLDOWN_CTR
    JMP _POLL_KEYBOARD
_UP
    LDA SPR0_Y
    CMP #21+25 
    BNE _MOVE_UP
    JMP _POLL_KEYBOARD
_MOVE_UP
    SEC
    SBC #32 
    STA SPR0_Y

    LDA CARD_PTR16+0 ; CARD_PTR16-= 40*4 (four rows)
    SEC
    SBC #(40*4)
    STA CARD_PTR16+0
    LDA CARD_PTR16+1
    SBC #0
    STA CARD_PTR16+1

    JMP _SET_MOVEMENT_COOLDOWN
_DOWN
    LDA SPR0_Y
    CMP #21+25+(32*3)
    BNE _MOVE_DOWN
    JMP _POLL_KEYBOARD
_MOVE_DOWN
    CLC
    ADC #32 
    STA SPR0_Y

    LDA CARD_PTR16+0 ; CARD_PTR16+= 40*4 (four rows)
    CLC
    ADC #(40*4)
    STA CARD_PTR16+0
    LDA CARD_PTR16+1
    ADC #0
    STA CARD_PTR16+1

    JMP _SET_MOVEMENT_COOLDOWN
_LEFT
    LDA SPR0_X
    CMP #12+8
    BNE _MOVE_LEFT
    JMP _POLL_KEYBOARD
_MOVE_LEFT
    SEC
    SBC #16 
    STA SPR0_X

    LDA CARD_PTR16+0 ; CARD_PTR16-= 4 (four columns)
    SEC
    SBC #4
    STA CARD_PTR16+0
    LDA CARD_PTR16+1
    SBC #0
    STA CARD_PTR16+1

    JMP _SET_MOVEMENT_COOLDOWN
_RIGHT
    LDA SPR0_X
    CMP #12+8+(16*5)
    BNE _MOVE_RIGHT
    JMP _POLL_KEYBOARD
_MOVE_RIGHT
    CLC
    ADC #16 
    STA SPR0_X

    LDA CARD_PTR16+0 ; CARD_PTR16+= 4 (four columns)
    CLC
    ADC #4
    STA CARD_PTR16+0
    LDA CARD_PTR16+1
    ADC #0
    STA CARD_PTR16+1

    JMP _SET_MOVEMENT_COOLDOWN

; helper for subroutine TEST_DRAW
DRAW_TILE
PHY
PHX
TXA
TAY
    ; pixel = A = LEVEL[CARD_INDEX] * 16 + TILE_COUNTER (each card is 4x4=16 tiles)
    LDA LEVEL, Y
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC TILE_COUNTER

    ; SCREEN_PTR[A] = pixel
    ; draw pixel pattern
    STA (SCREEN_PTR)

    ; compute color of current tile
    ; color = COLOR_DATA[LEVEL[CARD_INDEX] * 16 + TILE_COUNTER]  (each card is 4x4=16 tiles)
    LDA LEVEL, Y
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC TILE_COUNTER
    PHY
    TAY

    ; color = COLOR_ROM_PTR[Y]
    LDA (COLOR_ROM_PTR), Y
    PLY

    ; COLOR_MEM_PTR16[A] = color
    ; set color for this tile
    STA (COLOR_MEM_PTR16)

    ; SCREEN_PTR++
    CLC
    LDA SCREEN_PTR+0
    ADC #1
    STA SCREEN_PTR+0
    LDA SCREEN_PTR+1
    ADC #0
    STA SCREEN_PTR+1

    ; COLOR_MEM_PTR16++
    CLC
    LDA COLOR_MEM_PTR16+0
    ADC #1
    STA COLOR_MEM_PTR16+0
    LDA COLOR_MEM_PTR16+1
    ADC #0
    STA COLOR_MEM_PTR16+1

    ; TILE_COUNTER++
    CLC
    LDA TILE_COUNTER
    ADC #$01
    STA TILE_COUNTER

    PLX
    PLY
    RTS


; This subroutine copies all tile pixels from ROM to Memory by using two 16-Bit pointers.
; Assumes CHAR_ROM_PTR16 (source) and CHAR_MEM_PTR16 (destination) is already initialized.
; 7*256 Bytes are copied
COPY_ALL_CHAR_TO_MEMORY
  LDX #0
  _COPY_ALL_CHAR_TO_MEMORY
    LDY #0
  
    ; inner loop
    _COPY_256_CHAR_TO_MEMORY
      LDA (CHAR_ROM_PTR16),Y
      STA (CHAR_MEM_PTR16), Y
      INY
    BNE _COPY_256_CHAR_TO_MEMORY

    ; CHAR_PTR16 += 256 (by inc high byte)
    LDA CHAR_ROM_PTR16+1
    INC A
    STA CHAR_ROM_PTR16+1

    ; CHAR_MEM_PTR16 += 256 (by inc high byte)
    LDA CHAR_MEM_PTR16+1
    INC A
    STA CHAR_MEM_PTR16+1

    INX
    CPX #$07
  BNE _COPY_ALL_CHAR_TO_MEMORY
  RTS

; TILE_COUNTER: from 0-15. Index in 4x4 (=16) tiles card image
; used to compute pixels and color
TEST_DRAW
    ; SCREEN_PTR = $C400
    LDA #$00
    STA SCREEN_PTR+0
    LDA #$C4
    STA SCREEN_PTR+1

    ; COLOR_MEM_PTR16 = $D800
    LDA #$00
    STA COLOR_MEM_PTR16+0
    LDA #$D8
    STA COLOR_MEM_PTR16+1

    ; Y = 0 (row counter)
    LDY #$00

    ; TILE_COUNTER = 0 (counts from 0 to 15 to draw 16 tiles for each card)
    LDA #$00
    STA TILE_COUNTER

    ; X = 0 (card index)
    LDX #$00

  ; This loop draws all 6x4 cards of 4x4 tiles each (4x4x6x4 tiles)
  _ALL_ROWS
  ; This loop draws one row of cards 6*4x4 tiles each
  _FOUR_ROWS
    LDA #$00
    STA CARD_INDEX
  ; This loop draws one row of 4*6 tiles
  _ROW
    ; Draw four tiles (of one card)
    ; notice the side-effects on the variables in the subroutine
    JSR DRAW_TILE
    JSR DRAW_TILE
    JSR DRAW_TILE
    JSR DRAW_TILE

    ; CARD_INDEX = CARD_INDEX + 1
    LDA CARD_INDEX
    CLC
    ADC #$01
    STA CARD_INDEX

    ; TILE_COUNTER = TILE_COUNTER - 4  (next tile in row starts)
    LDA TILE_COUNTER
    SEC
    SBC #$04
    STA TILE_COUNTER

    ; X++
    INX

    ; check if tiles of one row are drawn (6 cards each row)
    LDA CARD_INDEX
    CMP #6
    BEQ _END_ROW
    JMP _ROW
  _END_ROW
    ; 24(=4*6) tiles of one row have now been drawn.

    ; TILE_COUNTER = TILE_COUNTER + 4
    LDA TILE_COUNTER
    CLC
    ADC #$04
    STA TILE_COUNTER

    ; SCREEN_PTR = SCREEN_PTR + 16
    ; (skip tiles to go to the beginning of the next row)
    CLC
    LDA SCREEN_PTR+0
    ADC #$10
    STA SCREEN_PTR+0
    LDA SCREEN_PTR+1
    ADC #0
    STA SCREEN_PTR+1

    ; COLOR_MEM_PTR16 = COLOR_MEM_PTR16 + 16
    ; (skip tiles to go to the beginning of the next row)
    CLC
    LDA COLOR_MEM_PTR16+0
    ADC #$10
    STA COLOR_MEM_PTR16+0
    LDA COLOR_MEM_PTR16+1
    ADC #0
    STA COLOR_MEM_PTR16+1

    ; X=X-6 (reset X for next part of cards)
    TXA
    SEC
    SBC CARDS_EACH_ROW
    TAX

    ; Y%4==0? (4 rows drawn)
    INY
    TYA
    AND #%00000011
    BEQ _END_FOUR_ROWS
    JMP _FOUR_ROWS
  _END_FOUR_ROWS
    ; CARDS_EACH_ROW cards of 4x4 tiles have been drawn

    ; X=X+CARDS_EACH_ROW (next set of cards processed in next interation)
    TXA
    CLC
    ADC CARDS_EACH_ROW
    TAX

    ; TILE_COUNTER = 0
    LDA #$00
    STA TILE_COUNTER

    ; Y==16? (4 card rows == 16 tile rows)
    CPY #16
    BEQ _END_DRAW
    JMP _ALL_ROWS
 _END_DRAW
    ; all cards have been drawn

    RTS






; MARK: Drawing

DRAW_CARD_AT_XY















; MARK: Utilities

; use noise for random value
GET_RANDOM_BYTE_TO_A
  ; switch voice 3 to noise mode with maximum frequency to generate random values in SID_V3OC ($D41B)
  LDA #$FF
  STA SID_V3FL
  LDA #$FF
  STA SID_V3FH
  LDA #$80
  STA SID_V3CT
  LDA SID_V3OC
  RTS








; MARK: - Data Segment

.include "graphics.asm"
.include "key_input.asm"

.include "tile_set0.asm"
.include "tile_set1.asm"
.include "tile_set2.asm"
.include "tile_set3.asm"

Text0 .TEXT "Food Memory"
Text1 .TEXT "PRESS SPACE TO CONTINUE."

.ALIGN 256
MOD_24
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    .BYTE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

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

SPRITEDATA
    .BYTE %00_00_00_00, %11_00_00_00, %00_00_00_00
    .BYTE %00_00_00_11, %11_11_00_00, %00_00_00_00
    .BYTE %00_00_00_11, %01_11_00_00, %00_00_00_00
    .BYTE %00_00_00_11, %01_11_00_00, %00_00_00_00
    .BYTE %00_00_00_11, %01_11_00_00, %00_00_00_00
    .BYTE %00_00_00_11, %01_11_00_00, %00_00_00_00
    .BYTE %00_00_00_11, %01_11_00_00, %00_00_00_00
    .BYTE %00_11_00_11, %01_11_11_00, %11_00_00_00
    .BYTE %11_11_11_11, %01_11_11_11, %11_11_11_00
    .BYTE %11_01_11_11, %01_11_01_11, %01_11_11_11
    .BYTE %11_01_01_11, %01_11_01_11, %01_11_01_11
    .BYTE %11_11_01_11, %01_11_01_11, %01_11_01_11
    .BYTE %00_11_01_01, %01_01_01_11, %01_11_01_11
    .BYTE %00_11_01_01, %01_01_01_01, %01_01_01_11
    .BYTE %00_11_01_01, %01_01_01_01, %01_01_01_11
    .BYTE %00_11_11_01, %01_01_01_01, %01_01_01_11
    .BYTE %00_11_11_01, %01_01_01_01, %01_01_01_11
    .BYTE %00_00_11_01, %01_01_01_01, %01_01_11_11
    .BYTE %00_00_11_11, %01_01_01_01, %01_11_11_11
    .BYTE %00_00_11_11, %11_11_11_11, %11_11_11_00
    .BYTE %00_00_00_11, %11_11_11_11, %11_00_00_00
    .BYTE %00_00_00_00


; End of the entire program
LAST
.ENDLOGICAL
