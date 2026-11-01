; 64tass --mw65c02 --nostart -o foodmem.bin foodmem.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < foodmem.bin
; plink -batch -serial "/dev/ttyUSB0" -sercfg "19200,8,1,n,N" < foodmem.bin
.include "codyconstants.asm"

; Zero page variables
RANDOM_VALUE  = $D0      ; TODO: used to select a random level
TILE_COUNTER  = $D1      ; 0-15: used to iterate over tiles in test draw 
SCREEN_PTR    = $D2      ; 16-Bit variable
COLOR_PTR     = $D4      ; 16-Bit variable
ROW_COUNTER   = $D6      ; 0-5: used to check if one row has been drawn
LEVEL_PTR     = $D7      ; 16-Bit variable

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

    ; TODO: compute random level
    ; TODO: free Y in subroutine to use this variable (refactoring)
    LDA #<LEVEL0       
    STA LEVEL_PTR+0
    LDA #>LEVEL0
    STA LEVEL_PTR+1  

    ; load food graphics, overwrite cody character data from title screen
    LDX #0         
 _COPYCHAR   
    LDA CHARDATA0,X
    STA $C800,X 
    LDA CHARDATA1,X
    STA $C900,X
    LDA CHARDATA2,X
    STA $CA00,X
    LDA CHARDATA3,X
    STA $CB00,X
    LDA CHARDATA4,X
    STA $CC00,X
    LDA CHARDATA5,X
    STA $CD00,X
    LDA CHARDATA6,X
    STA $CE00,X
    INX
    ; copy character bytes, use X overflow to copy 7*256 ~= 1.75K of memory  
    BNE _COPYCHAR 
    
    ; draw open cards
    JSR TEST_DRAW

_GAME_LOOP
JMP _GAME_LOOP

; helper for subroutine TEST_DRAW
DRAW_TILE
    ; pixel = LEVEL[X] * 16 + TILE_COUNTER (each card is 4x4=16 tiles)
    LDA LEVEL0, X
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
    LDA LEVEL0, X
    ASL
    ASL
    ASL
    ASL
    CLC 
    ADC TILE_COUNTER
    PHX
    TAX
    LDA COLOR_DATA, X
    PLX
    
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

    ; X = 0 (level counter)
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

.include "graphics.asm"
.include "key_input.asm"

.include "tile_set1.asm"

Text0 .TEXT "Food Memory"
Text1 .TEXT "PRESS SPACE TO CONTINUE."

LEVEL0 .BYTE 1,2,3,4,5,6
       .BYTE 6,5,4,3,2,1
       .BYTE 7,8,9,10,11,12
       .BYTE 7,8,9,10,11,12

LAST         ; End of the entire program

.ENDLOGICAL