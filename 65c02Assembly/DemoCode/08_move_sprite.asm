; moves a sprite (Joystick)

.include "codyconstants.asm"

SPRITEX = $D0
SPRITEY = $D1

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E2            ; Set border color (Bits 0-3) to red=2 
                                ; and set color memory to $D800 (A000+14*1024=D800), E=14
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
            LDA #$95            ; Set character memory to $C800 (A000+5*2048=C800)
                                ; and set screen memory location $C400 (A000+9*1024=C400)
            STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)

            LDA #$E2            ; Store shared colors (light blue=14 and red=2)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

            LDX #0              ; Copy sprite data into video memory
_COPYSPRT   LDA SPRITEDATA,X
            STA $A400,X         ; sprite pixel data location. Page 327 and 535 
            INX
            CPX #64
            BNE _COPYSPRT
            
            LDA #$01            ; Sprite bank 0, white as common sprite color (not used in jet sprite)
            STA VID_SPRC        ; VID_SPRC=$D006 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in jet sprite)
            STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
            LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
            STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)  

            LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
            STA VIA_DDRA
            LDA #$06            ; Set VIA to read joystick 1
            STA VIA_IORA

            LDA #(80+12)        ; sprite X variable
            STA SPRITEX          
            LDA #(100+21)       ; sprite Y variable
            STA SPRITEY                 

_LOOP      
            LDA VIA_IORA        ; Read joystick
            LSR A
            LSR A
            LSR A
            
            BIT #8              ; Joystick right
            BEQ _RIGHT
            
            BIT #4              ; Joystick left
            BEQ _LEFT

            BIT #2              ; Joystick down 
            BEQ _DOWN
            
            BIT #1              ; Joystick up 
            BEQ _UP

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
            JSR WAITBLANK       ; Wait for the next frame

            LDA SPRITEX         ; sprite X
            STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
            LDA SPRITEY         ; sprite Y
            STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)

            JMP _LOOP           ; Game loops 


WAITBLANK

_WAITVIS    LDA VID_BLNK        ; Wait until the blanking is zero (drawing the screen)
            BNE _WAITVIS
            
_WAITBLANK  LDA VID_BLNK        ; Wait until the blanking is one (not drawing the screen)
            BEQ _WAITBLANK
            
            RTS

SPRITEDATA

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; Jet sprite data
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_01_01_01, %00_00_00_00
.BYTE %00_00_00_00, %01_01_01_01, %01_00_00_00
.BYTE %00_00_00_01, %01_01_01_01, %01_01_00_00
.BYTE %00_00_00_01, %01_01_01_01, %01_01_00_00
.BYTE %00_00_00_01, %01_00_01_00, %01_01_00_00
.BYTE %00_00_00_01, %00_00_01_00, %00_01_00_00
.BYTE %00_00_00_00, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_01_01_01, %00_00_00_00
.BYTE %00_00_00_00, %01_01_01_01, %01_00_00_00
.BYTE %00_00_00_00, %01_00_01_00, %01_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

LAST                            ; End of the entire program

.ENDLOGICAL
