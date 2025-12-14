; 64tass --mw65c02 --nostart -o codytennis.bin codytennis.asm

.include "codyconstants.asm"

; Variables (program state)

RIGHT_BAT_Y = $D0
LEFT_BAT_Y  = $D1
BALL_X      = $D2
BALL_Y      = $D3
MOVE_RIGHT  = $D4 ; 0=false 1=true
MOVE_DOWN   = $D5 ; 0=false 1=true

; Constants
LEFT_BAT_X = 12+4
RIGHT_BAT_X = 12*13
BAT_HEIGT = 42

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E7            ; Set border color (Bits 0-3) to yello=7 
                                ; and set color memory to $D800 (A000+14*1024=D800), E=14
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
            LDA #$95            ; Set character memory to $C800 (A000+5*2048=C800)
                                ; and set screen memory location $C400 (A000+9*1024=C400)
            STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)

            LDA #$E2            ; Store shared colors (light blue=14 and red=2)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

            JSR INIT_SPRITE_GRAPHICS
            JSR INIT_INPUT
            STZ MOVE_RIGHT      ; 0=false, ball moves to the left
            STZ MOVE_DOWN       ; 0=false, ball moves up
            
_LOOP      
            JSR HANDLE_INPUT    ; Change game state according to input
            JSR UPDATE_BALL_POS ; Change ball position OR change direction
            JSR WAIT_BLANK      ; Wait for the next frame
            JSR DRAW_GAME       ; Draw the Game
            JMP _LOOP           ; Game loops 


; SUBROUTUNE WAIT BLANK
WAIT_BLANK
_WAITVIS    LDA VID_BLNK        ; Wait until the blanking is zero (drawing the screen)
            BNE _WAITVIS
            
_WAITBLANK  LDA VID_BLNK        ; Wait until the blanking is one (not drawing the screen)
            BEQ _WAITBLANK
            
            RTS

; SUBROUTINE INIT SPRITE GRAPHICS
; 5 Sprites: 0-1 left bat, 2-3 right bat, 4 ball
; Sprite state: 4 Bytes. Sprite data: 64 Bytes
INIT_SPRITE_GRAPHICS
            LDX #0              ; Copy sprite data into video memory
_COPYSPRT   LDA SPRITEDATA,X
            STA $A400,X         ; sprite pixel data location. Page 327 and 535 
            INX
            CPX #(64*3)         ; copy data for 3 sprites (bat sprite is reused)
            BNE _COPYSPRT
            
            LDA #$01            ; Sprite bank 0, white as common sprite color (not used in jet sprite)
            STA VID_SPRC        ; VID_SPRC=$D006 (see codyconstants.asm)

                                ; set color of every sprite
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in sprite)
            STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in sprite)
            STA SPR0_COL+4      ; SPR0_COL=$D082+4 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in sprite)
            STA SPR0_COL+8      ; SPR0_COL=$D082+8 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in sprite)
            STA SPR0_COL+12     ; SPR0_COL=$D082+12 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in sprite)
            STA SPR0_COL+16     ; SPR0_COL=$D082+16 (see codyconstants.asm)

                                ; set sprite data location for every sprite
            LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
            STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)
            LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
            STA SPR0_PTR+4      ; SPR0_PTR=$D083+4 (see codyconstants.asm)
            LDA #$11            ; ($A400-$A000)/$80=$11 see Page 327 for explaination
            STA SPR0_PTR+8      ; SPR0_PTR=$D083+8 (see codyconstants.asm)
            LDA #$11            ; ($A400-$A000)/$80=$11 see Page 327 for explaination
            STA SPR0_PTR+12     ; SPR0_PTR=$D083+12 (see codyconstants.asm)
            LDA #$12            ; ($A400-$A000)/$C0=$12 see Page 327 for explaination
            STA SPR0_PTR+16     ; SPR0_PTR=$D083+16 (see codyconstants.asm)

            LDA #LEFT_BAT_X     ; set initial left bat sprite X position
            STA SPR0_X 
            STA SPR0_X+4       
            LDA #(21*6)         ; set initial left bat sprite Y position
            STA LEFT_BAT_Y
            STA SPR0_Y
            ADC #20
            STA SPR0_Y+4

            LDA #RIGHT_BAT_X    ; set initial right bat sprite X position
            STA SPR0_X+8 
            STA SPR0_X+12       
            LDA #(21*6)         ; set initial right bat sprite Y position
            STA RIGHT_BAT_Y
            STA SPR0_Y+8
            ADC #20
            STA SPR0_Y+12

            LDA #(12*6+12)      ; set initial ball sprite
            STA BALL_X 
            STA SPR0_X+16
            LDA #(21*6)
            STA BALL_Y
            STA SPR0_Y+16 

            RTS

; SUBROUTINE INIT INPUT
INIT_INPUT
            LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
            STA VIA_DDRA

            RTS

; SUBROUTUNE DRAW GAME
DRAW_GAME
            LDA LEFT_BAT_Y      ; draw left bat (two sprites)
            STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)
            ADC #20
            STA SPR0_Y+4        ; SPR0_Y=$D081+4 (see codyconstants.asm)

            LDA RIGHT_BAT_Y     ; draw right bat (two sprites)
            STA SPR0_Y+8        ; SPR0_Y=$D081+8 (see codyconstants.asm)
            ADC #20
            STA SPR0_Y+12       ; SPR0_Y=$D081+12 (see codyconstants.asm)
    
            LDA BALL_X          ; draw ball sprite
            STA SPR0_X+16       
            LDA BALL_Y
            STA SPR0_Y+16  
            RTS

; SUBROUTINE HANLDE INPUT
HANDLE_INPUT
            LDA #$04            ; Set VIA to read keyboard row 5
            STA VIA_IORA
            LDA VIA_IORA        ; Read keyboard
            LSR A
            LSR A
            LSR A
            CMP #%00011110      ; S Key
            BEQ _LEFT_BAT_DOWN

            LDA #$05            ; Set VIA to read keyboard row 6
            STA VIA_IORA
            LDA VIA_IORA        ; Read keyboard
            LSR A
            LSR A
            LSR A           
            CMP #%00011110      ; W Key
            BEQ _LEFT_BAT_UP

            JMP _INPUT_LEFT_DONE 

_LEFT_BAT_DOWN
            LDA LEFT_BAT_Y     ; SPRITEY++ If not at bottom
            CMP #(21*8)
            BEQ _INPUT_LEFT_DONE
            
            ADC #2
            STA LEFT_BAT_Y    
            JMP _INPUT_LEFT_DONE
_LEFT_BAT_UP
            LDA LEFT_BAT_Y     ; SPRITEY-- if not at top
            CMP #(21+1)        ; +1 to get even number
            BEQ _INPUT_LEFT_DONE

            SBC #2
            STA LEFT_BAT_Y     ; update value
            JMP _INPUT_LEFT_DONE

_INPUT_LEFT_DONE
            LDA #$06            ; Set VIA to read joystick 1
            STA VIA_IORA
            LDA VIA_IORA        ; Read joystick
            LSR A
            LSR A
            LSR A

            BIT #2              ; Joystick down 
            BEQ _RIGHT_BAT_DOWN
            
            BIT #1              ; Joystick up 
            BEQ _RIGHT_BAT_UP
           
            JMP _INPUT_DONE
_RIGHT_BAT_DOWN
            LDA RIGHT_BAT_Y    ; SPRITEY++ If not at bottom
            CMP #(21*8)
            BEQ _INPUT_DONE
            
            ADC #2
            STA RIGHT_BAT_Y    
            JMP _INPUT_DONE
_RIGHT_BAT_UP
            LDA RIGHT_BAT_Y    ; SPRITEY-- if not at top
            CMP #(21+1)        ; +1 to get even number
            BEQ _INPUT_DONE

            SBC #2
            STA RIGHT_BAT_Y    ; update value
            JMP _INPUT_DONE
_INPUT_DONE
            RTS

; SUBROUTINE UPDATE BALL POS
; first check if x movement has hit a wall. 
; then check if y movement has hit a wall.
UPDATE_BALL_POS
            LDA MOVE_RIGHT
            BEQ _MOVE_LEFT  ;MOVE_RIGHT=0=false
            JMP _MOVE_RIGHT ;MOVE_RIGHT=1=true 
_MOVE_RIGHT 
            LDA BALL_X
            CMP #(160+8) ; screen size (160 pixel) + empty part of ball sprite (8 pixel)
            BEQ _SET_MOVEMENT_TO_LEFT

            ; check bat right collision by negating this condition
            ; IF
            ;   BALL_X == RIGHT_BAT_X+BALL_WIDTH
            ;   AND (BALL_Y >= RIGHT_BAT_Y AND BALL_Y <= RIGHT_BAT_Y+BAT_HEIGT)
            ; THEN GOTO _SET_MOVEMENT_TO_LEFT
            ; ELSE GOTO _UPDATE_RIGHT

            CMP #(RIGHT_BAT_X+4)
            BNE _UPDATE_RIGHT ; update if BALL_X != RIGHT_BAT_X+4
            LDA BALL_Y
            SEC
            SBC RIGHT_BAT_Y
            BMI _UPDATE_RIGHT ; update if BALL_Y-RIGHT_BAT_Y<0 (BALL_Y<RIGHT_BAT_Y)
            LDA RIGHT_BAT_Y
            ADC #(BAT_HEIGT)
            SEC
            SBC BALL_Y
            BMI _UPDATE_RIGHT ; update if (RIGHT_BAT_Y+BAT_HEIGT)-BALL_Y<0 (RIGHT_BAT_Y+BAT_HEIGT<BALL_Y)

            JMP _SET_MOVEMENT_TO_LEFT ; THEN brnach: condition is true

_UPDATE_RIGHT
            LDA BALL_X
            CLC
            ADC #1
            STA BALL_X
            JMP _END_OF_X_UPDATE
_MOVE_LEFT 
            LDA BALL_X
            CMP #(12)   ; first visible sprite position
            BEQ _SET_MOVEMENT_TO_RIGHT

            ; check bat right collision by negating this condition
            ; IF
            ;   BALL_X == LEFT_BAT_X+BAT_WIDTH
            ;   AND (BALL_Y >= LEFT_BAT_Y AND BALL_Y <= LEFT_BAT_Y+BAT_HEIGT)
            ; THEN GOTO _SET_MOVEMENT_TO_RIGHT
            ; ELSE GOTO _UPDATE_LEFT
            CMP #(LEFT_BAT_X+4)
            BNE _UPDATE_LEFT ; update if BALL_X != LEFT_BAT_X+8
            LDA BALL_Y
            SEC
            SBC LEFT_BAT_Y
            BMI _UPDATE_LEFT ; update if BALL_Y-LEFT_BAT_Y<0 (BALL_Y<LEFT_BAT_Y)
            LDA LEFT_BAT_Y
            ADC #(BAT_HEIGT)
            SEC
            SBC BALL_Y
            BMI _UPDATE_LEFT ; update if (LEFT_BAT_Y+BAT_HEIGT)-BALL_Y<0 (LEFT_BAT_Y+BAT_HEIGT<BALL_Y)

            JMP _SET_MOVEMENT_TO_RIGHT

_UPDATE_LEFT
            LDA BALL_X
            SEC
            SBC #1
            STA BALL_X
            JMP _END_OF_X_UPDATE
_SET_MOVEMENT_TO_LEFT
            STZ MOVE_RIGHT
            JMP _END_OF_X_UPDATE
_SET_MOVEMENT_TO_RIGHT
            LDA #1
            STA MOVE_RIGHT
            JMP _END_OF_X_UPDATE
_END_OF_X_UPDATE

            LDA MOVE_DOWN
            BEQ _MOVE_UP   ; MOVE_DOWN=0=false
            JMP _MOVE_DOWN ; MOVE_DOWN=1=true 
_MOVE_DOWN
            LDA BALL_Y
            CMP #(21)   ; first visible sprite position
            BEQ _SET_MOVEMENT_TO_UP

            SBC #1
            STA BALL_Y
            JMP _END_OF_Y_UPDATE
_MOVE_UP
            LDA BALL_Y
            CMP #(200+16) ; screen size (200 pixel) + empty part of ball sprite (16 pixel)
            BEQ _SET_MOVEMENT_TO_DOWN

            ADC #1
            STA BALL_Y
            JMP _END_OF_Y_UPDATE
_SET_MOVEMENT_TO_UP
            STZ MOVE_DOWN
            JMP _END_OF_Y_UPDATE
_SET_MOVEMENT_TO_DOWN
            LDA #1
            STA MOVE_DOWN
            JMP _END_OF_Y_UPDATE
_END_OF_Y_UPDATE
            RTS

; DATA SECTION
SPRITEDATA

.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00 ; left bat sprite (pixels left)
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01 ; right bat sprite (pixels right)
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00

.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00 ; ball sprite (4x8 Pixels)
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
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

LAST                            ; End of the entire program

.ENDLOGICAL
