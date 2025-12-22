; PacMan clone
; 

.include "codyconstants.asm"

; Aviod magic numbers
TILE_NUM         = 28                   ; number of tiles
DIGIT_TILE_START = 18                   ; start of tiles 0 .. 9 in tile data
SPRITE_WIDTH     = 12
SPRITE_HEIGHT    = 21

; Game state
TILE_X           = $A0                  ; current x tile pos of pacman
TILE_Y           = $A1                  ; current y tile pos of pacman
TILE_INDEX       = $A2                  ; index of the current tile (computed by tile x, y)
TILE_NUMBER      = $A4                  ; number of the current tile (computed by tile x, y)
PACMAN_FRAME_NUM = $A5                  ; current frame number, used for animation
PACMAN_DIRECTION = $A6

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                              ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)          ; Ending address (so we know when we're done loading)

; The actual program.
.LOGICAL    ADDR                        ; The actual program gets loaded at ADDR

MAIN                                    ; The program starts running from here
                LDA #$E0                ; Set border color (Bits 0-3) to black=0 
                                        ; and set color memory to $D800 (A000+14*1024=D800), E=14
                STA VID_COLR            ; VID_COLR=$D002 (see codyconstants.asm)
                LDA #$95                ; Set character memory to $C800 (A000+5*2048=C800)
                                        ; and set screen memory location $C400 (A000+9*1024=C400)
                STA VID_BPTR            ; VID_BPTR=$D003 (see codyconstants.asm)
                
                LDA #$E7                ; Store shared colors (light blue=14 and yellow=7)
                STA VID_SCRC            ; VID_SCRC=$D005 (see codyconstants.asm)
                
                JSR LOAD_TILES 
                JSR INIT_INPUT
                JSR INIT_SPRITES
                
                STZ TILE_X 
                STZ TILE_Y
                STZ PACMAN_FRAME_NUM
                ; TODO PACMAN_DIRECTION

_LOOP       
                JSR COMPUTE_PLAYER_TILE
                JSR READ_PLAYER_TILE
                JSR PRINT_DEBUG
                JSR WAIT_BLANK
                JSR HANDLE_INPUT
                JSR EAT_PILL
                JSR COMPUTE_PACMAN_FRAME
                JMP _LOOP               ; Game loop

; SUBROUTUNE WAIT BLANK
WAIT_BLANK
_WAITVIS        LDA VID_BLNK            ; Wait until the blanking is zero (drawing the screen)
                BNE _WAITVIS
            
_WAITBLANK      LDA VID_BLNK            ; Wait until the blanking is one (not drawing the screen)
                BEQ _WAITBLANK
                
                RTS

; SUBROUTINE INIT INPUT
INIT_INPUT
                LDA #$07                ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
                STA VIA_DDRA
                
                RTS

; SUBROUTINE INIT SPRITES
; copy sprite data and init sprite banks: 4 ghosts and one pacman
INIT_SPRITES
                LDX #0                  ; Copy sprite data into video memory
_COPYSPRT0      LDA SPRITEDATA0,X
                STA $A400,X             ; sprite pixel data location. Page 327 and 535 
                INX
                CPX #255              ; copy data for 4 sprite frames 
                BNE _COPYSPRT0

                LDX #0                  
_COPYSPRT1      LDA SPRITEDATA1,X
                STA $A500,X             ; + $100  
                INX
                CPX #255              ; copy data for 4 sprite frames 
                BNE _COPYSPRT1

                LDX #0                  
_COPYSPRT2      LDA SPRITEDATA2,X
                STA $A600,X             ; + $100  
                INX
                CPX #127              ; copy data for 2 sprite frames 
                BNE _COPYSPRT2
                
                LDA #$00                ; Sprite bank 0, black as common sprite color 
                STA VID_SPRC            ; VID_SPRC=$D006 (see codyconstants.asm)
                
                LDA #$19                ; ($A400-$A000)/$FF=$13 see Page 327 for explaination
                STA SPR0_PTR            ; SPR0_PTR=$D083 (see codyconstants.asm)
                LDA #$12                ; red=2 color 1, white=1 color 2 
                STA SPR0_COL            ; SPR0_COL=$D082 (see codyconstants.asm)
                LDA #80                 ; set initial sprite X position
                STA SPR0_X       
                LDA #(21+8)
                STA SPR0_Y
                
                LDA #$19                ; light red ghost, like above
                STA SPR0_PTR+4          
                LDA #$1A                ; light red=A color 1, white=1 color 2 
                STA SPR0_COL+4
                LDA #(80-8) 
                STA SPR0_X+4       
                LDA #(21+32)
                STA SPR0_Y+4
                
                LDA #$19                ; light blue ghost, like above
                STA SPR0_PTR+8 
                LDA #$1E                ; light blue=E color 1, white=1 color 2 
                STA SPR0_COL+8 
                LDA #(16)
                STA SPR0_X+8       
                LDA #(21+32)
                STA SPR0_Y+8
                
                LDA #$19                ; light gray ghost, like above
                STA SPR0_PTR+12 
                LDA #$1D                ; lihgt gray=D color 1, white=1 color 2 
                STA SPR0_COL+12      
                LDA #(32)            
                STA SPR0_X+12       
                LDA #(21+40)
                STA SPR0_Y+12
                
                LDA #$10                ; pacman, like above
                STA SPR0_PTR+16      
                LDA #$07                ; yellow=7 color 1, black=1 color 2 (not used in sprite)
                STA SPR0_COL+16      
                LDA #(12+64)         
                STA SPR0_X+16       
                LDA #(21+96)
                STA SPR0_Y+16
                RTS

; SUBROUTINE PRINT DEBUG (tile x, tile y, tile number) to screen 
PRINT_DEBUG
                LDY #24                 ; Y=tile index (postion on the screen)
                LDA TILE_X
                TAX
                LDA LUT_BinToBCD,X      ; convert to BCD
                AND #$0F                ; get low byte
                CLC
                ADC #(DIGIT_TILE_START) ; look up digit graphic ...
                STA $C400, Y            ; and put it at position Y
                
                LDY #23                 ; Y=tile index (postion on the screen)
                LDA TILE_X 
                TAX
                LDA LUT_BinToBCD,X      ; convert to BCD
                LSR A                   ; get high byte by shifting 4 Bits to the right
                LSR A 
                LSR A 
                LSR A 
                CLC
                ADC #(DIGIT_TILE_START) ; look up digit graphic ...
                STA $C400, Y            ; and put it at position Y
                
                LDY #64                 ; print Tile_Y the same way
                LDA TILE_Y
                TAX
                LDA LUT_BinToBCD,X
                AND #$0F
                CLC
                ADC #(DIGIT_TILE_START)
                STA $C400, Y

                LDY #63
                LDA TILE_Y
                TAX
                LDA LUT_BinToBCD,X
                LSR A 
                LSR A 
                LSR A 
                LSR A 
                CLC
                ADC #(DIGIT_TILE_START)
                STA $C400, Y

                LDY #104                ; print tile number (value)
                LDA TILE_NUMBER
                TAX
                LDA LUT_BinToBCD,X
                AND #$0F
                CLC
                ADC #(DIGIT_TILE_START)
                STA $C400, Y

                LDY #103
                LDA TILE_NUMBER
                TAX
                LDA LUT_BinToBCD,X
                LSR A 
                LSR A 
                LSR A 
                LSR A 
                CLC
                ADC #(DIGIT_TILE_START)
                STA $C400, Y

                RTS

; SUBROUTINE COMPUTE TILE
; Save PacMan Sprite pos (x,y)
; First visible position: SPRITE_WIDTH=12, SPRITE_HEIGHT=21 middle of sprite 5,5
COMPUTE_PLAYER_TILE
                LDA SPR0_X+16           ; (X-(12+5)) / 4 pixels
                SEC
                SBC #(SPRITE_WIDTH-5)
                LSR 
                LSR 
                STA TILE_X

                LDA SPR0_Y+16           ; (X-(21+5)) / 8 pixels
                SEC
                SBC #(SPRITE_HEIGHT-5)
                LSR 
                LSR 
                LSR
                STA TILE_Y
                RTS

; SUBROUTINE READ PLAYER TILE
; Reads the tile number of the current tile of the player.
; Compute the tile index: TILE_INDEX (16-Bit).
; Compute the tile value at this index: TILE_NUMBER (8-Bit).
READ_PLAYER_TILE
                LDA #$00                ; use immediate of screen mem (we compute an index)
                STA TILE_INDEX+0
                LDA #$C4             
                STA TILE_INDEX+1
                LDY TILE_Y              ; loop y times 
_COMPUTE_ROW
                CLC 
                LDA TILE_INDEX+0
                ADC #40                 ; 40 tiles in a row
                STA TILE_INDEX+0
                LDA TILE_INDEX+1
                ADC #0
                STA TILE_INDEX+1
                DEY
                CPY #0
                BNE _COMPUTE_ROW

                CLC 
                LDA TILE_INDEX+0
                ADC TILE_X              ; compute column
                STA TILE_INDEX+0
                LDA TILE_INDEX+1
                ADC #0
                STA TILE_INDEX+1

                LDA (TILE_INDEX)       ; use index to compute value
                STA TILE_NUMBER

                RTS

; SUBROUTINE LOAD TILES
; Load level by copying tiles from tile map
LOAD_TILES
                LDX #0               ; Copy character
_COPYCHAR       LDA TILE_DATA,X
                STA $C800,X
                INX
                CPX #(8*TILE_NUM)    ; every tile is 8 Bytes big, TILE_NUM tiles
                BNE _COPYCHAR
                
                LDY #0               ; every loop copies 240 tile numbers, except the last one
_ROWS
                LDA MAP_DATA,Y      
                STA $C400, Y
                INY
                CPY #240
                BNE _ROWS
                
                LDY #0
_ROWS2
                LDA MAP_DATA2,Y      
                STA $C4F0, Y            ; + 240 
                INY
                CPY #240
                BNE _ROWS2
                
                LDY #0
_ROWS3
                LDA MAP_DATA3,Y      
                STA $C5E0, Y            ; + 240*2
                INY
                CPY #240
                BNE _ROWS3
                
                LDY #0
_ROWS4
                LDA MAP_DATA4,Y      
                STA $C6D0, Y            ; + 240*3
                INY
                CPY #240
                BNE _ROWS4
                
                LDY #0
_ROWS5
                LDA MAP_DATA5,Y      
                STA $C7C0, Y            ; + 240*4
                INY
                CPY #40                 ; copy only 40 tile numbers
                BNE _ROWS5
                RTS

; SUBROUTINE HANLDE INPUT
; Reads WASD / Joystick Keys and moved PacMan sprite. 
; Call this at V-Blank
HANDLE_INPUT
                LDA #$01                ; Set VIA to read keyboard row 2
                STA VIA_IORA
                LDA VIA_IORA            ; Read keyboard
                LSR A
                LSR A
                LSR A           
                CMP #%00011110          ; A Key pressed
                BEQ _LEFT
                
                LDA VIA_IORA            ; Read keyboard
                LSR A
                LSR A
                LSR A           
                CMP #%00011101          ; D Key pressed
                BEQ _RIGHT
                
                LDA #$04                ; Set VIA to read keyboard row 5
                STA VIA_IORA
                LDA VIA_IORA            ; Read keyboard
                LSR A
                LSR A
                LSR A
                CMP #%00011110          ; S Key pressed
                BEQ _DOWN
                
                LDA #$05                ; Set VIA to read keyboard row 6
                STA VIA_IORA
                LDA VIA_IORA            ; Read keyboard
                LSR A
                LSR A
                LSR A           
                CMP #%00011110          ; W Key pressed
                BEQ _UP
                
                LDA #$06                ; Set VIA to read joystick 1
                STA VIA_IORA
                LDA VIA_IORA            ; Read joystick
                LSR A
                LSR A
                LSR A
                
                BIT #8                  ; Joystick right pressed
                BEQ _RIGHT
                
                BIT #4                  ; Joystick left pressed
                BEQ _LEFT
                
                BIT #2                  ; Joystick down pressed
                BEQ _DOWN
                
                BIT #1                  ; Joystick up pressed
                BEQ _UP
                
                JMP _INPUT_DONE 

_UP
                LDA SPR0_Y+16
                DEC A
                STA SPR0_Y+16           ; update value: move pacman up
                LDA #%00000001
                STA PACMAN_DIRECTION 
                JMP _INPUT_DONE
_DOWN
                LDA SPR0_Y+16
                INC A
                STA SPR0_Y+16           ; update value: move pacman down
                LDA #%00000010
                STA PACMAN_DIRECTION 
                JMP _INPUT_DONE
_LEFT
                LDA SPR0_X+16
                DEC A
                STA SPR0_X+16           ; update value: move pacman left 
                LDA #%00000100
                STA PACMAN_DIRECTION 
                JMP _INPUT_DONE
_RIGHT
                LDA SPR0_X+16
                INC A
                STA SPR0_X+16           ; update value: move pacman right 
                LDA #%00001000
                STA PACMAN_DIRECTION 
                JMP _INPUT_DONE
_INPUT_DONE
                RTS

; SUBROUTINE EAT PILL
; Remove pill if PacMan is on "pill tile"
; Call this at V-Blank
EAT_PILL
                ; 0 = empty, 1 = pill
                ; if tile_number = 1 then
                ; tiles[tile_index] = 0
                LDA TILE_NUMBER
                CMP #1
                BNE _END_OF_EAT

                ; tiles[tile_index] = 0
                LDA #0
                STA (TILE_INDEX)
_END_OF_EAT
                RTS

; SUBROUTINE COMPUTE PACMAN FRAME
; TODO: refactor this, remove code dupl.
COMPUTE_PACMAN_FRAME
                LDA PACMAN_FRAME_NUM
                CMP #0
                BEQ _FRAME_0
                CMP #12
                BEQ _FRAME_1
                CMP #24
                BEQ _FRAME_2
                JMP _END_OF_FRAME_SELECT
_FRAME_0
                LDA #$10                    
                STA SPR0_PTR+16         ; switch to computed frame numer / sprite graphic index
                JMP _END_OF_FRAME_SELECT
_FRAME_1
                LDX #$11
                LDA PACMAN_DIRECTION
                CMP #%00000001
                BEQ _FRAME_1_UP
                CMP #%00000010
                BEQ _FRAME_1_DOWN
                CMP #%00001000
                BEQ _FRAME_1_RIGHT
                ; pacman moves left
                TXA
                JMP _SWITCH_FRAME_TO_1  

_FRAME_1_UP     ; frame $17
                TXA
                CLC
                ADC #6
                JMP _SWITCH_FRAME_TO_1
_FRAME_1_DOWN   ; frame $15
                TXA
                CLC
                ADC #4
                JMP _SWITCH_FRAME_TO_1
_FRAME_1_RIGHT  ; frame $13
                TXA
                CLC
                ADC #2
                JMP _SWITCH_FRAME_TO_1                

_SWITCH_FRAME_TO_1                      ; switch to computed frame numer / sprite graphic index                    
                STA SPR0_PTR+16                      
                JMP _END_OF_FRAME_SELECT                          
_FRAME_2
                LDX #$12
                LDA PACMAN_DIRECTION
                CMP #%00000001
                BEQ _FRAME_2_UP
                CMP #%00000010
                BEQ _FRAME_2_DOWN
                CMP #%00001000
                BEQ _FRAME_2_RIGHT
                ; pacman moves left
                TXA
                JMP _SWITCH_FRAME_TO_2  

_FRAME_2_UP     ; frame $18
                TXA
                CLC
                ADC #6
                JMP _SWITCH_FRAME_TO_2
_FRAME_2_DOWN   ; frame $16
                TXA
                CLC
                ADC #4
                JMP _SWITCH_FRAME_TO_2
_FRAME_2_RIGHT  ; frame $14
                TXA
                CLC
                ADC #2
                JMP _SWITCH_FRAME_TO_2   
 _SWITCH_FRAME_TO_2                     ; switch to computed frame numer / sprite graphic index
                STA SPR0_PTR+16            
                JMP _END_OF_FRAME_SELECT
_END_OF_FRAME_SELECT
                LDA PACMAN_FRAME_NUM    ; next frame num
                INC A 
                STA PACMAN_FRAME_NUM
                CMP #36                 ; reset frame num, if frame max: restart animation
                BNE _END_OF_ROUTINE
                STZ PACMAN_FRAME_NUM
_END_OF_ROUTINE
                RTS

; DATA SECTION
SPRITEDATA0

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $10: pacman, circle=(left/right/up/down), 2
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $11: pacman, left, 0
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_00_00_01, %01_01_01_01, %00_00_00_00
.BYTE %00_00_00_00, %01_01_01_01, %00_00_00_00
.BYTE %00_00_00_00, %01_01_01_01, %00_00_00_00
.BYTE %00_00_00_01, %01_01_01_01, %00_00_00_00
.BYTE %00_00_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $12: pacman, left, 1
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_00_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_00_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $13: pacman, right, 0
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

SPRITEDATA1

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $14: pacman, right, 1
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $15: pacman, down, 0
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_00, %00_01_01_01, %00_00_00_00
.BYTE %01_01_00_00, %00_00_01_01, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_01, %00_00_00_00
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

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $16: pacman, down, 1
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_00, %00_01_01_01, %00_00_00_00
.BYTE %01_01_00_00, %00_00_01_01, %00_00_00_00
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

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; $17: pacman, up, 0
.BYTE %00_01_00_00, %00_00_01_00, %00_00_00_00
.BYTE %01_01_00_00, %00_00_01_01, %00_00_00_00
.BYTE %01_01_01_00, %00_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

SPRITEDATA2

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; $18: pacman, up, 1
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_01, %00_00_00_00
.BYTE %01_01_00_00, %00_00_01_01, %00_00_00_00
.BYTE %01_01_01_00, %00_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00
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

.BYTE %00_00_01_01, %01_01_00_00, %00_00_00_00 ; $19: ghost
.BYTE %00_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_10_10_01, %01_10_10_01, %00_00_00_00
.BYTE %01_11_10_01, %01_11_10_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %00_00_00_00
.BYTE %01_01_00_01, %01_00_01_01, %00_00_00_00
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

TILE_DATA

  .BYTE %00000000   ; 0: "empty tile" 
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; 1: "small pill"
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00100000
  .BYTE %00100000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; 2: "big pill"
  .BYTE %00000000
  .BYTE %00101000
  .BYTE %00101000
  .BYTE %00101000
  .BYTE %00101000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; 3:
  .BYTE %00000000
  .BYTE %00111111
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000011
  .BYTE %11001100
  .BYTE %11001100

  .BYTE %00000000   ; 4:
  .BYTE %00000000
  .BYTE %11111111
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %11111111
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; 5:
  .BYTE %00000000
  .BYTE %11111100
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11000011
  .BYTE %00110011
  .BYTE %00110011

  .BYTE %11001100   ; 6:
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100

  .BYTE %11000011  ; 7:
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011

  .BYTE %00110011  ; 8:
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00110011

  .BYTE %00000000   ; 9:
  .BYTE %00000000
  .BYTE %11111111
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011

  .BYTE %11001100   ; 10:
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11000011
  .BYTE %11000000
  .BYTE %00111111
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; 11:
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %11111111
  .BYTE %00000000
  .BYTE %11111111
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00110011   ; 12:
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %11000011
  .BYTE %00000011
  .BYTE %11111100
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %11000011   ; 13:
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %00000000
  .BYTE %11111111
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %11000011   ; 14:
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %00111100

  .BYTE %00111100   ; 15:
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011
  .BYTE %11000011

  .BYTE %00000000   ; 16:
  .BYTE %00000000
  .BYTE %11111100
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111100
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; 17:
  .BYTE %00000000
  .BYTE %00111111
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %00111111
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000 ; "0"
  .BYTE %00001100  
  .BYTE %00110011
  .BYTE %00111111
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00001100

  .BYTE %00000000 ; "1"
  .BYTE %00001100  
  .BYTE %00111100
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00111111

  .BYTE %00000000 ; "2"
  .BYTE %00001100  
  .BYTE %00110011
  .BYTE %00000011
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00110000
  .BYTE %00111111

  .BYTE %00000000 ; "3"
  .BYTE %00001100  
  .BYTE %00110011
  .BYTE %00000011
  .BYTE %00001100
  .BYTE %00000011
  .BYTE %00110011
  .BYTE %00001100

  .BYTE %00000000 ; "4"
  .BYTE %00000011  
  .BYTE %00001111
  .BYTE %00110011
  .BYTE %00111111
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011

  .BYTE %00000000 ; "5"
  .BYTE %00111111  
  .BYTE %00110000
  .BYTE %00111100
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00110011
  .BYTE %00001100

  .BYTE %00000000 ; "6"
  .BYTE %00001100  
  .BYTE %00110011
  .BYTE %00110000
  .BYTE %00111100
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00001100

  .BYTE %00000000 ; "7"
  .BYTE %00111111  
  .BYTE %00110011
  .BYTE %00000011
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00001100

  .BYTE %00000000 ; "8"
  .BYTE %00001100  
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00001100
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00001100

  .BYTE %00000000 ; "9"
  .BYTE %00001100  
  .BYTE %00110011
  .BYTE %00110011
  .BYTE %00001100
  .BYTE %00000011
  .BYTE %00110011
  .BYTE %00001100

; used to convert from twos-complement to BCD
LUT_BinToBCD
                .BYTE %00000000
                .BYTE %00000001
                .BYTE %00000010
                .BYTE %00000011
                .BYTE %00000100
                .BYTE %00000101
                .BYTE %00000110
                .BYTE %00000111
                .BYTE %00001000
                .BYTE %00001001
                .BYTE %00010000
                .BYTE %00010001
                .BYTE %00010010
                .BYTE %00010011
                .BYTE %00010100
                .BYTE %00010101
                .BYTE %00010110
                .BYTE %00010111
                .BYTE %00011000
                .BYTE %00011001
                .BYTE %00100000
                .BYTE %00100001
                .BYTE %00100010
                .BYTE %00100011
                .BYTE %00100100
                .BYTE %00100101
                .BYTE %00100110
                .BYTE %00100111
                .BYTE %00101000
                .BYTE %00101001
                .BYTE %00110000
                .BYTE %00110001
                .BYTE %00110010
                .BYTE %00110011
                .BYTE %00110100
                .BYTE %00110101
                .BYTE %00110110
                .BYTE %00110111
                .BYTE %00111000
                .BYTE %00111001
                .BYTE %01000000
                .BYTE %01000001
                .BYTE %01000010
                .BYTE %01000011
                .BYTE %01000100
                .BYTE %01000101
                .BYTE %01000110
                .BYTE %01000111
                .BYTE %01001000
                .BYTE %01001001

MAP_DATA
  .BYTE 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 9, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 3, 4, 5, 1, 3, 4, 5, 1, 7, 1, 3, 4, 5, 1, 3, 4, 5, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 2, 6, 0, 8, 1, 6, 0, 8, 1, 7, 1, 6, 0, 8, 1, 6, 0, 8, 2, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1,10,11,12, 1,10,11,12, 1,14, 1,10,11,12, 1,10,11,12, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
MAP_DATA2
  .Byte 6, 1, 3, 4, 5, 1,15, 1, 3, 4, 4, 4, 5, 1,15, 1, 3, 4, 5, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1,10,11,12, 1, 7, 1,10,11, 9,11,12, 1, 7, 1,10,11,12, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 1, 1, 1, 1, 7, 1, 1, 1, 7, 1, 1, 1, 7, 1, 1, 1, 1, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 10,4, 4, 4, 5, 1, 7, 4,16, 0,14, 0,17, 4, 7, 1, 3, 4, 4, 4,12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 0, 0, 0, 0, 8, 1, 7, 0, 0, 0, 0, 0, 0, 0, 7, 1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 4, 4, 4, 4,12, 1,14, 0, 3, 4, 4, 4, 5, 0,14, 1,10,11,11,11,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
MAP_DATA3
  .Byte 0, 0, 0, 0, 0, 1, 0, 0, 6, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 4, 4, 4, 4, 5, 1,15, 0, 10,11,11,11,12,0,15, 1, 3, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 0, 0, 0, 0, 8, 1, 7, 0, 0, 0, 0, 0, 0, 0, 7, 1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 3, 4, 4, 4,12, 1,14, 0,17, 4, 9, 4,16,0,14, 1,10, 4, 4, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1,17, 4, 5, 1,17, 4,16, 1,14, 1,17, 4,16, 1, 3, 4,16, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
MAP_DATA4
  .Byte 6, 2, 1, 1, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 6, 1, 1, 2, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 10,4, 5, 1, 8, 1,15, 1, 3, 4, 4, 4, 5, 1,15, 1, 6, 1, 3, 4,12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 3,11,12, 1,14, 1, 7, 1,10,11, 9,11,12, 1, 7, 1,14, 1, 10,11, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 1, 1, 1, 1, 7, 1, 1, 1, 7, 1, 1, 1, 7, 1, 1, 1, 1, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1,17, 4, 4, 4, 4, 4,16, 1,14, 1,17, 4, 4, 4, 4, 4,16, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .Byte 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
MAP_DATA5
  .Byte 10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,12,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

LAST                            ; End of the entire program

.ENDLOGICAL
