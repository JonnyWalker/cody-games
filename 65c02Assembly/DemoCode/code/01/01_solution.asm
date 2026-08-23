; Changes the border color to blue

.include "codyconstants.asm"

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E6            ; Set border color (Bits 0-3) to blue=6 
                                ; and set color memory to $D800 (A000+14*1024=D800, E=14)
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)                
_DONE       JMP _DONE           ; Loops forever

LAST                            ; End of the entire program

.ENDLOGICAL
