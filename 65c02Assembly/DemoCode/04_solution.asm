; print the text "HELLO CODY"

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

            LDX #0              ; Copy character
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #64             ; 8*8=40
            BNE _COPYCHAR


            LDA #1              ; print H
            STA $C400
            LDA #2              ; print E
            STA $C401
            LDA #3              ; print L
            STA $C402
            LDA #3              ; print L
            STA $C403
            LDA #4              ; print O
            STA $C404

            LDA #5              ; print C
            STA $C406
            LDA #4              ; print O
            STA $C407
            LDA #6              ; print D
            STA $C408
            LDA #7              ; print D
            STA $C409

_DONE       JMP _DONE           ; Loops forever

CHARDATA

  .BYTE %00000000   ; "empty tile"
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %11001100   ; H
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11111100
  .BYTE %11111100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100

  .BYTE %11111100   ; E
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111100
  .BYTE %11111100
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111100

  .BYTE %11000000   ; L
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111100

  .BYTE %11111100   ; O
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11111100

  .BYTE %11111100   ; C
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111100

  .BYTE %11110000   ; D
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11110000

  .BYTE %11001100   ; Y
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11111100
  .BYTE %00110000
  .BYTE %00110000
  .BYTE %00110000
  .BYTE %00110000

LAST                            ; End of the entire program

.ENDLOGICAL
