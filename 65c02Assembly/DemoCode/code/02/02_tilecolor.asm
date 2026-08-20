; Changes the border color to red and draw one line in cyan

.include "codyconstants.asm"

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E2            ; Set border color (Bits 0-3) to red=2 
                                ; and set color memory to $D800 ($A000+14*1024=$D800), E=14 (Bits 7-4)
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)

            LDX #0              ; Change tile color
_COPYCOLOR  LDA #$03            ; forground color (0=black) backgrund color (3=cyan)
            STA $D800,X         ; Copy colors to color memory $D800 to $D828 (40 Bytes)
            INX
            CPX #40
            BNE _COPYCOLOR  

_DONE       JMP _DONE           ; Loops forever

LAST                            ; End of the entire program

.ENDLOGICAL
