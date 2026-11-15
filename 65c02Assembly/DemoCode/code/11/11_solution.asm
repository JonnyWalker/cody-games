; moving sprites with collision detection

.include "codyconstants.asm"

SPRITEX = $D0
SPRITEY = $D1
COLORPTR = $D2
FRAMECTR = $D4

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            JSR INIT_VIDEO_MEM
            JSR INIT_SPRITES
            JSR DRAW_LEVEL
            JSR DRAW_STATUS_BAR

            STZ FRAMECTR        ; FRAMECTR=0
           
            LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
            STA VIA_DDRA
            LDA #$06            ; Set VIA to read joystick 1
            STA VIA_IORA         

_LOOP      
            LDA VIA_IORA        ; Read joystick
            LSR A
            LSR A
            LSR A

            BIT #16             ; Joystick fire button
            BEQ _FIRE
            
            BIT #8              ; Joystick right
            BEQ _RIGHT
            
            BIT #4              ; Joystick left
            BEQ _LEFT

            BIT #2              ; Joystick down 
            BEQ _DOWN
            
            BIT #1              ; Joystick up 
            BEQ _UP

            JMP _DRAW

_FIRE       JSR FIRE
            JMP _DRAW
_RIGHT      INC SPRITEX         ; SPRITEX++
            JMP _DRAW
_LEFT       DEC SPRITEX         ; SPRITEX--
            JMP _DRAW
_DOWN       INC SPRITEY         ; SPRITEY++
            JMP _DRAW
_UP         DEC SPRITEY         ; SPRITEY--
            JMP _DRAW
_DRAW
            JSR CHECK_COLLISION
            JSR WAITBLANK       ; Wait for the next frame

            LDA FRAMECTR        ; FRAMECTR++
            INC A
            STA FRAMECTR

            LDA SPRITEX         ; sprite X
            STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
            LDA SPRITEY         ; sprite Y
            STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)

            JSR MOVE_SPRITES
            JSR MOVE_BULLET

            JMP _LOOP           ; Game loops 

.include "graphics.asm"
.include "init_video.asm"
.include "draw_game.asm"
.include "sprite_data.asm"
.include "tile_data.asm"
.include "game_logic.asm"


LAST                            ; End of the entire program

.ENDLOGICAL
