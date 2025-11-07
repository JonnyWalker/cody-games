;
; COMPUTE_TILE
;
; Computes the containing tile index of a point (x,y).
; Hint: Use this to compute a bounding box of a Sprite
;
; ARG0: pixel x
; ARG1: pixel y
; RET_VAL0: tile index x
; RET_VAL1: tile index y
COMPUTE_TILE 
  STZ RET_VAL+0       ; init with zero
  STZ RET_VAL+1
  LDA ARG+0           ; x = x-12
  SBC #12
  STA ARG+0
  LDA ARG+1           ; y = y-21
  SBC #21 
  STA ARG+1

  LDA ARG+1           ; Set Y to ROW of player (tiles are 8 Pixel high)
  LSR A
  LSR A
  LSR A
  STA RET_VAL+1

  LDA ARG+0           ; Set X to COLUMN of player (tiles are 4 Pixel wide)
  LSR A
  LSR A
  STA RET_VAL+0
  RTS

; ARG0: x (tile index)
; ARG1: y (tile index)
; ARG2: map data index (low)
; ARG3: map data index (high)
; ARG4: map width (assume < 256)
COMPUTE_MAP_INDEX
  ; compute y*width to get row
  LDA ARG+2
  STA RET_VAL+0
  LDA ARG+3    
  STA RET_VAL+1

  LDX ARG+1
  
  _COMPUTE_ROW          ; row in tile map = MAP_WIDTH*y
  CPX #0                
  BEQ _COMPUTE_ROW_END
  
  CLC                 ; Increment tile index by MAP_WIDTH
  LDA RET_VAL+0
  ADC ARG+4
  STA RET_VAL+0
  LDA RET_VAL+1
  ADC #0
  STA RET_VAL+1

  DEX
  BRA _COMPUTE_ROW
_COMPUTE_ROW_END

  CLC                 ; Increment tile index by x
  LDA RET_VAL+0
  ADC ARG+0
  STA RET_VAL+0
  LDA RET_VAL+1
  ADC #0
  STA RET_VAL+1

  RTS


; ARG0: pixel x
; ARG1: pixel y
; ARG2: map data index (low)
; ARG3: map data index (high)
; ARG4: map width (assume < 256)
; ARG5: tile number (> collision, <= no collision)
; sort your tiles to use this function by collision
; RET_VAL = 0  no colission
; RET_VAL = 1  colission
COMPUTE_COLISSION       
  JSR COMPUTE_TILE
  
  LDA RET_VAL+0       ; pass tile index x 
  STA ARG+0
  LDA RET_VAL+1       ; pass tile index y
  STA ARG+1
  JSR COMPUTE_MAP_INDEX
  LDA (RET_VAL)       ; Read current tile in Tile Map
  SBC ARG+5
  SBC 1
  BMI COMPUTE_TILE_INDEX_FALSE
  BRA COMPUTE_TILE_INDEX_TRUE

COMPUTE_TILE_INDEX_TRUE:
  LDA #1
  STA RET_VAL
  RTS
COMPUTE_TILE_INDEX_FALSE:
  LDA #0
  STA RET_VAL
  RTS
