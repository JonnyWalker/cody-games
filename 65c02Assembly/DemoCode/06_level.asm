; draws a level by changing tile colors

.include "codyconstants.asm"

COLORPTR   = $D0

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

            LDA #$00            ; set color pointer to $D800
            STA COLORPTR+0
            LDA #$D8 
            STA COLORPTR+1

            LDX #0              ; Change tile color 
_XLOOP  
            LDY #0              
_COPYCOLOR  LDA #$05            ; forground color (0=black) backgrund color (5=green)
            STA (COLORPTR),Y         ; Copy colors to color memory 
            INY
            CPY #10
            BNE _COPYCOLOR
_COPYCOLOR2 LDA #$0E            ; forground color (0=black) backgrund color (E=light blue)
            STA (COLORPTR),Y         ; Copy colors to color memory 
            INY
            CPY #30
            BNE _COPYCOLOR2
_COPYCOLOR3 LDA #$05            ; forground color (0=black) backgrund color (5=green)
            STA (COLORPTR),Y    ; Copy colors to color memory 
            INY
            CPY #40
            BNE _COPYCOLOR3   

            CLC                 ; Increment color pointer to next row
            LDA COLORPTR+0
            ADC #40
            STA COLORPTR+0
            LDA COLORPTR+1
            ADC #0
            STA COLORPTR+1

            INX                 ; check end of outer loop (25 rows)
            CPX #25
            BNE _XLOOP  

_DONE       JMP _DONE           ; Loops forever


LAST                            ; End of the entire program

.ENDLOGICAL
