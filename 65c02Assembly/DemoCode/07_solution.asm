; draws a sprite in the middle of the screen

.include "codyconstants.asm"

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
            LDA #(12+80)        ; sprite X
            STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
            LDA #(21+100)       ; sprite Y
            STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in jet sprite)
            STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
            LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
            STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)           

_DONE       JMP _DONE           ; Loops forever

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
