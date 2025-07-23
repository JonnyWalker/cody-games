;
; COMPUTE_TILE
;
; Computes the containing tile index of a point (x,y).
; The tile map starts at (map_x, map_y).
; Hint: Use this to compute a bounding box of a Sprite
;
; ARG0: x
; ARG1: y
; ARG2: map_x
; ARG3: map_y
; RET_VAL (2 bytes): index of the tile inside the map
COMPUTE_TILE 
  LDA ARG+2           ; Set tile index to map start
  STA RET_VAL+0
  LDA ARG+3
  STA RET_VAL+1 

  LDA ARG+1           ; Set X to ROW of player (tiles are 8 Pixel high)
  LSR A
  LSR A
  LSR A
  SBC #2              ; see page 329. Player start is not (0,0)
  TAX

_COMPUTE_ROW          ; row in tile map = MAP_WIDTH*y
  CPX #0                
  BEQ _COMPUTE_ROW_END

  CLC                 ; Increment tile index by MAP_WIDTH
  LDA RET_VAL+0
  ADC MAP_WIDTH
  STA RET_VAL+0
  LDA RET_VAL+1
  ADC #0
  STA RET_VAL+1

  DEX
  BRA _COMPUTE_ROW
_COMPUTE_ROW_END 

  LDA ARG+0           ; Set X to COLUMN of player (tiles are 4 Pixel wide)
  LSR A
  LSR A
  SBC #2              ; see page 329
  STA TEMP

  CLC                 ; Increment tile index by 1
  LDA RET_VAL+0
  ADC TEMP
  STA RET_VAL+0
  LDA RET_VAL+1
  ADC #0
  STA RET_VAL+1

  RTS
