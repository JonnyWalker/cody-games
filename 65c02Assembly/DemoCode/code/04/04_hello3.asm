; prints the text "HELLO" using the CODSCII characters from ROM
; not supported by https://github.com/iTitus/cody_emulator 
; 64tass --mw65c02 --nostart -o 04_hello3.bin 04_hello3.asm

.include "codyconstants.asm"

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

; print text of length at (row, column)
PRINT .macro text, column, row, length
    LDX #0
 _Print_Text
    LDA \text, X
    STA 50176+\column+\row*40, X ; 50176=$C400, 40 characters each row
    INX
    CPX #\length
    BNE _Print_Text
    .endmacro

MAIN                            ; The program starts running from here
            LDA #$E2            ; Set border color (Bits 0-3) to red=2 
                                ; and set color memory to $D800 (A000+14*1024=D800), E=14
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
            LDA #$95            ; Set character memory to $C800 (A000+5*2048=C800)
                                ; and set screen memory location $C400 (A000+9*1024=C400)
            STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)

            JSR LOAD_CODSCII_TO_CHAR_MEM
            LDA #$E0
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            #PRINT Text0, 0, 0, 5

_DONE       JMP _DONE           ; Loops forever

.include "graphics.asm"

Text0 .TEXT "HELLO"

LAST                            ; End of the entire program

.ENDLOGICAL
