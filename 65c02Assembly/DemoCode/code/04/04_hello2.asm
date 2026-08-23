; prints the text "HELLO" using the CODSCII characters from ROM
; not supported by https://github.com/iTitus/cody_emulator 

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

            JSR LOAD_CODSCII_TO_CHAR_MEM
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            LDA #$E0            ; set color for letters (CODSCII uses color 1)
            STA $D800
            LDA #$E0
            STA $D801
            LDA #$E0
            STA $D802
            LDA #$E0
            STA $D803
            LDA #$E0
            STA $D804

            LDA #'H'            ; print H
            STA $C400
            LDA #'E'            ; print E
            STA $C401
            LDA #'L'            ; print L
            STA $C402
            LDA #'L'            ; print L
            STA $C403
            LDA #'O'            ; print O
            STA $C404

_DONE       JMP _DONE           ; Loops forever

.include "graphics.asm"

LAST                            ; End of the entire program

.ENDLOGICAL
