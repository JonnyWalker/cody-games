; MARK: SUB DRAW_TILE
; helper for subroutine TEST_DRAW
;
; clobbers Y, A
; CARD_VALUE: which card to draw 
; TILE_COUNTER: which tile of the card to draw
; SCREEN_PTR: destination
; COLOR_MEM_PTR16: destination
; COLOR_ROM_PTR: source
; incs SCREEN_PTR and COLOR_ROM_PTR by one
DRAW_TILE
    ; pixel = A = CARD_VALUE 16 + TILE_COUNTER (each card is 4x4=16 tiles)
    LDA CARD_VALUE
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
    ; color = COLOR_DATA[CARD_VALUE] * 16 + TILE_COUNTER]  (each card is 4x4=16 tiles)
    LDA CARD_VALUE
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC TILE_COUNTER
    TAY
    ; color = COLOR_ROM_PTR[Y]
    LDA (COLOR_ROM_PTR), Y

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

    RTS


; MARK: SUB TEST_DRAW
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
    STA CARD_COLUMN_INDEX
  ; This loop draws one row of 4*6 tiles
  _ROW
    ; Draw four tiles (of one card)
    ; notice the side-effects on the variables in the subroutine
    PHY
    LDA LEVEL, X
    STA CARD_VALUE
    JSR DRAW_TILE
    INC TILE_COUNTER

    LDA LEVEL, X
    STA CARD_VALUE
    JSR DRAW_TILE
    INC TILE_COUNTER

    LDA LEVEL, X
    STA CARD_VALUE
    JSR DRAW_TILE
    INC TILE_COUNTER

    LDA LEVEL, X
    STA CARD_VALUE
    JSR DRAW_TILE
    INC TILE_COUNTER

    PLY

    ; CARD_COLUMN_INDEX = CARD_COLUMN_INDEX + 1
    LDA CARD_COLUMN_INDEX
    CLC
    ADC #$01
    STA CARD_COLUMN_INDEX

    ; TILE_COUNTER = TILE_COUNTER - 4  (next tile in row starts)
    LDA TILE_COUNTER
    SEC
    SBC #$04
    STA TILE_COUNTER

    ; X++
    INX

    ; check if tiles of one row are drawn (6 cards each row)
    LDA CARD_COLUMN_INDEX
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

; MARK: SUB DRAW_CARD_AT_CARD_PTR16
; Arguments: ZP Variable
; CARD_PTR16: top left tile of 4x4 tile card in screen memory
; CARD_VALUE
DRAW_CARD_AT_CARD_PTR16

    LDA CARD_PTR16+0
    STA SCREEN_PTR+0
    LDA CARD_PTR16+0
    STA COLOR_MEM_PTR16+0

    LDA CARD_PTR16+1
    CLC
    ADC #$C4 ; set to screen memory
    STA SCREEN_PTR+1
    LDA CARD_PTR16+1
    CLC
    ADC #$D8 ; set to color memory
    STA COLOR_MEM_PTR16+1

    STZ TILE_COUNTER
    LDY #$00
_LOOP
    LDX #$00
_ROW_LOOP
    PHY
    JSR DRAW_TILE
    PLY

    INC TILE_COUNTER
    INX
    CPX #$04
    BNE _ROW_LOOP

    CLC
    LDA SCREEN_PTR+0
    ADC #$24
    STA SCREEN_PTR+0
    LDA SCREEN_PTR+1
    ADC #$00
    STA SCREEN_PTR+1

    CLC
    LDA COLOR_MEM_PTR16+0
    ADC #$24
    STA COLOR_MEM_PTR16+0
    LDA COLOR_MEM_PTR16+1
    ADC #$00
    STA COLOR_MEM_PTR16+1

    INY
    CPY #$04
    BNE _LOOP

    RTS
