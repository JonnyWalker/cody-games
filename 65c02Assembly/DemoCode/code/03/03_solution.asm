; draw 20 tiles of type one in the middel row of the screen by starting at tile 490

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

            LDX #0              ; Change tile color of first row
_COPYCOLOR  LDA #$83
            STA $D9ea,X         ; start at tile 490 ($1f4)
            INX
            CPX #20
            BNE _COPYCOLOR  

            LDX #0              ; Copy two tiles (2x8 Bytes) into character memory
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #16
            BNE _COPYCHAR

            LDX #0              ; Copy 20 tiles into screen memory
_COPYSCRN   LDA #1
            STA $C5ea,X         ; start at tile 490 ($1f4)
            INX
            CPX #20
            BNE _COPYSCRN

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

  .BYTE %00000000   ; Tile graphic using all four colors
  .BYTE %00000000
  .BYTE %01010101
  .BYTE %01010101
  .BYTE %10101010
  .BYTE %10101010
  .BYTE %11111111
  .BYTE %11111111

LAST                            ; End of the entire program

.ENDLOGICAL
