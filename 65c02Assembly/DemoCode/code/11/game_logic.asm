; 3=fuel, 4=heli, 5=plane, 6=ship, 7=ship
ARR_ENEMY_WIDTH
  .BYTE 5, 8, 9, 11, 11
ARR_ENEMY_HEIGHT
  .BYTE 19, 6, 5, 5, 5

CHECK_COLLISION
    LDX #12
    LDY #0
_COLLISION_LOOP
    ; Check if sprite is too far left
    CLC
    LDA SPR0_X        
    SBC SPR0_X, X           ; jet_x - sprite_x
    CMP ARR_ENEMY_WIDTH, Y  ; sprite width-1
    BPL _NO_COLLISION

    ; Check if sprite is too far right
    CLC
    LDA SPR0_X, X
    SBC SPR0_X        ; sprite_x - jet_x
    CMP #6            ; jet width-1
    BPL _NO_COLLISION 

    ; Check if sprite is too far up
    CLC
    LDA SPR0_Y
    SBC SPR0_Y, X           ; jet_y - sprite_y
    CMP ARR_ENEMY_HEIGHT, Y ; sprite height-1
    BPL _NO_COLLISION

    ; Check if sprite is too far down
    CLC
    LDA SPR0_Y, X
    SBC SPR0_Y        ; sprite_y - jet_y
    CMP #13           ; jet height-1 
    BPL _NO_COLLISION
    JMP _COLLISION_DETECTED
_NO_COLLISION 
    INX
    INX
    INX
    INX
    INY
    CPY #5
    BNE _COLLISION_LOOP ; check next sprite (5 sprite total)

    LDA #$47            ; change color to yellow (=7)
    STA SPR0_COL 
    RTS
_COLLISION_DETECTED
    LDA #$74            ; change color to red (=4)
    STA SPR0_COL 
    RTS

; Subroutine moves all enemys every 8 frames
MOVE_SPRITES
    ; if FRAMECTR%8!=0 then skip subroutine
    LDA FRAMECTR
    AND #$07
    BEQ _MOVE_SPRITES
    RTS

_MOVE_SPRITES
    LDX #12             ; Index in sprite bank 0
    LDY #0              ; Sprite counter
_MOVE_LOOP
    ; SPRITE_Y++
    LDA SPR0_Y, X
    INC A
    STA SPR0_Y, X

    ; if SPRITE_Y==160 then SPRITE_Y=0
    CMP #160
    BNE _SKIP_Y_RESET
    LDA #$00
    STA SPR0_Y, X
 _SKIP_Y_RESET

    ; X += 4
    INX
    INX
    INX
    INX
    ; Y ++
    INY
    CPY #5
    BNE _MOVE_LOOP ; check next sprite (5 sprite total)
    RTS
