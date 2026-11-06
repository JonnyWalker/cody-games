; 64tass --mw65c02 --nostart -o foodmem.bin foodmem.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < foodmem.bin
; plink -batch -serial "/dev/ttyUSB0" -sercfg "19200,8,1,n,N" < foodmem.bin
.include "codyconstants.asm"

; MARK: - ZP Variables
RANDOM_VALUE    = $D0   ; TODO: used to select a random level
TILE_COUNTER    = $D1   ; 0-15: used to iterate over tiles in test draw
SCREEN_PTR      = $D2   ; 16-Bit variable
COLOR_PTR       = $D4   ; 16-Bit variable
ROW_COUNTER     = $D6   ; 0-5: used to check if one row has been drawn
CHAR_PTR16      = $DB   ; 16-Bit variable to choose a tile set
CHAR_MEM_PTR16  = $DD
COLOR_PTR2      = $DF   ; TODO: usefull comment

GPRNG_SEED      = $F0   ; Galois PRNG Seed


; CONSTANTS
CARDS_EACH_ROW = #$06

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

; show title screen, compute random value and wait for space key
_TITLE_SCREEN
    ; overwrites all other graphics
    JSR LOAD_CODSCII_TO_CHAR_MEM

    ; clear with white=1 and black=0
    LDA #$10
    ; replace all characters with empty character
    JSR CLEAR_SCREEN

    ; prints "Food Memory"
    #PRINT Text0, 0, 1, 11
    ; prints "PRESS SPACE TO CONTINUE."
    #PRINT Text1, 0, 23, 24

  _WAIT_FOR_SPACE
    ; compute random value between 0 and 255
    LDA RANDOM_VALUE
    INC A
    STA RANDOM_VALUE

    ; exit loop on space key
    JSR KEY_TO_A
    CMP #$20
    BNE _WAIT_FOR_SPACE

_NEW_GAME
    ; clear with white=1 and black=0
    LDA #$10
    ; replace all characters with empty character
    JSR CLEAR_SCREEN





INIT_RNG                ; initialize the RNG
    LDA RANDOM_VALUE    ; with RANDOM_VALUE
    BNE _skip           ; as seed; make sure
    INC A               ; value is not 0
_skip                   ;
    STA GPRNG_SEED      ;

INIT_RANDOM_LEVEL       ; idea: for all cards,
                        ; draw random index
                        ;
    LDY #25             ; 24 iterations.
                        ; we start at 25 so that
                        ; Y div 2 produces card
                        ; values 12...1, each
                        ; exactly twice. if we
                        ; started at 24 we would
                        ; produce one 0.
_loop                   ;
    JSR GET_RAND_BYTE   ; get random byte,
    TAX                 ; and convert to
    LDA MOD_24,X        ; index into level
    TAX                 ;
    LDA LEVEL,X         ; check if card at that index is 0.
    BNE _loop           ; if its not, then theres already a
                        ; card assigned; try again.
    TYA                 ;
    LSR                 ; div 2 to map 25...1 to 12...1
    STA LEVEL,X         ; store card id at chosen index
    DEY                 ;
    CPY #1              ;
    BNE _loop           ;





    ; randomly select one of
    ; 4 available memory sets
    JSR GET_RAND_BYTE
    AND #3
    ASL
    TAX
    LDA MEMORY_SETS_PIXELS,X
    LDY MEMORY_SETS_COLORS,X
    STA CHAR_PTR16 + 0
    STY COLOR_PTR2 + 0
    INX
    LDA MEMORY_SETS_PIXELS,X
    LDY MEMORY_SETS_COLORS,X
    STA CHAR_PTR16 + 1
    STY COLOR_PTR2 + 1

    ; TODO: move out of code
    ; into data 'segment' so
    ; we don't have to jump
    ; over these arrays...
    BRA skip_arrays



LEVEL
    .BYTE 0,0,0,0,0,0  ; level data.
    .BYTE 0,0,0,0,0,0  ;
    .BYTE 0,0,0,0,0,0  ; 0 if no card assigned,
    .BYTE 0,0,0,0,0,0  ; value 1...12 otherwise.

; TODO: fix naming (missing underscore)
; TODO: add another tileset (vegetables?)
MEMORY_SETS_PIXELS
    .WORD TILE_SET0
    .WORD TILE_SET1
    .WORD TILE_SET2
    .WORD TILE_SET2

MEMORY_SETS_COLORS
    .WORD COLOR_DATA0
    .WORD COLOR_DATA1
    .WORD COLOR_DATA2
    .WORD COLOR_DATA2

skip_arrays





    LDA #$00
    STA CHAR_MEM_PTR16+0
    LDA #$C8
    STA CHAR_MEM_PTR16+1

   LDX #0
 _COPYCHAR_OUTER_LOOP
    LDY #0
  _COPYCHAR
    LDA (CHAR_PTR16),Y
    STA (CHAR_MEM_PTR16), Y

    INY
    BNE _COPYCHAR

     ; CHAR_PTR16 += 256
    LDA CHAR_PTR16+1
    INC A
    STA CHAR_PTR16+1

    ; CHAR_MEM_PTR16 += 256
    LDA CHAR_MEM_PTR16+1
    INC A
    STA CHAR_MEM_PTR16+1

    INX
    CPX #$07
   BNE _COPYCHAR_OUTER_LOOP




;    LDX #0
; _COPYCHAR
;    LDA CHARDATA0,X
;    STA $C800,X
;    LDA CHARDATA1,X
;    STA $C900,X
;    LDA CHARDATA2,X
;    STA $CA00,X
;    LDA CHARDATA3,X
;    STA $CB00,X
;    LDA CHARDATA4,X
;    STA $CC00,X
;    LDA CHARDATA5,X
;    STA $CD00,X
;    LDA CHARDATA6,X
;    STA $CE00,X
;    INX
;    ; copy character bytes, use X overflow to copy 7*256 ~= 1.75K of memory
;    BNE _COPYCHAR

    ; draw open cards
    JSR TEST_DRAW

_GAME_LOOP
JMP _GAME_LOOP

; helper for subroutine TEST_DRAW
DRAW_TILE
PHY
PHX
TXA
TAY
    ; pixel = LEVEL[X] * 16 + TILE_COUNTER (each card is 4x4=16 tiles)
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
    ; color = COLOR_DATA[LEVEL[X] * 16 + TILE_COUNTER]  (each card is 4x4=16 tiles)
    LDA LEVEL, Y
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC TILE_COUNTER
    PHY
    TAY

    ; TODO: use pointer and set pointer in setup according to random value
    LDA (COLOR_PTR2), Y
    PLY

    ; COLOR_PTR[A] = color
    ; set color for this tile
    STA (COLOR_PTR)

    ; SCREEN_PTR++
    CLC
    LDA SCREEN_PTR+0
    ADC #1
    STA SCREEN_PTR+0
    LDA SCREEN_PTR+1
    ADC #0
    STA SCREEN_PTR+1

    ; COLOR_PTR++
    CLC
    LDA COLOR_PTR+0
    ADC #1
    STA COLOR_PTR+0
    LDA COLOR_PTR+1
    ADC #0
    STA COLOR_PTR+1

    ; TILE_COUNTER++
    CLC
    LDA TILE_COUNTER
    ADC #$01
    STA TILE_COUNTER

    PLX
    PLY
    RTS

; TILE_COUNTER: from 0-15. Index in 4x4 (=16) tiles card image
; used to compute pixels and color
TEST_DRAW
    ; SCREEN_PTR = $C400
    LDA #$00
    STA SCREEN_PTR+0
    LDA #$C4
    STA SCREEN_PTR+1

    ; COLOR_PTR = $D800
    LDA #$00
    STA COLOR_PTR+0
    LDA #$D8
    STA COLOR_PTR+1

    ; Y = 0 (row counter)
    LDY #$00

    ; TILE_COUNTER = 0 (counts from 0 to 15 to draw 16 tiles for each card)
    LDA #$00
    STA TILE_COUNTER

    ; X = 0 (card index)
    LDX #$00

  ; This loop draws all 6x4 cards of 4x4 tiles each
  _ALL_ROWS
  ; This loop draws one row of cards 6*4x4 tiles each
  _FOUR_ROWS
    LDA #$00
    STA ROW_COUNTER
  ; This loop draws one row of 4*6 tiles
  _ROW
    ; Draw four tiles (of one card)
    ; notice the side-effects on the variables in the subroutine
    JSR DRAW_TILE
    JSR DRAW_TILE
    JSR DRAW_TILE
    JSR DRAW_TILE

    ; ROW_COUNTER = ROW_COUNTER + 1
    LDA ROW_COUNTER
    CLC
    ADC #$01
    STA ROW_COUNTER

    ; TILE_COUNTER = TILE_COUNTER - 4  (next tile in row starts)
    LDA TILE_COUNTER
    SEC
    SBC #$04
    STA TILE_COUNTER

    ; X++
    INX

    ; check if tiles of one row are drawn (6 cards each row)
    LDA ROW_COUNTER
    CMP #6
    BEQ _END_ROW
    JMP _ROW
  _END_ROW
    ; 24(=4*6) tiles of one row have been draw.

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

    ; COLOR_PTR = COLOR_PTR + 16
    ; (skip tiles to go to the beginning of the next row)
    CLC
    LDA COLOR_PTR+0
    ADC #$10
    STA COLOR_PTR+0
    LDA COLOR_PTR+1
    ADC #0
    STA COLOR_PTR+1

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

; https://6502.org/users/mycorner/6502/code/prng.html
GET_RAND_BYTE
    LDA	GPRNG_SEED	    ; get seed
	ASL			        ; shift byte
	BCC	_skip		    ; branch if no carry
	EOR	#$CF		    ; else XOR with $CF
_skip
	STA GPRNG_SEED	    ; save number as next seed
	RTS			        ; done


.include "graphics.asm"
.include "key_input.asm"

.include "tile_set0.asm"
.include "tile_set1.asm"
.include "tile_set2.asm"

Text0 .TEXT "Food Memory"
Text1 .TEXT "PRESS SPACE TO CONTINUE."

MOD_24
    .ALIGN 256
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


LAST         ; End of the entire program

.ENDLOGICAL