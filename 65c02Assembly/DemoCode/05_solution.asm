; prints a text after the q key has been pressed
; and change the bg color of the text after the C Key has been pressed

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

            LDA #$07              ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)
            STA VIA_DDRA 

            LDX #0              ; Copy character
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #40             ; 5*8=40
            BNE _COPYCHAR


                                ; see page 65 in Cody Computer Book
            LDA #5              ; read in row 6 (zero indexed)
            STA VIA_IORA
_READKEY    LDA VIA_IORA        ; wait for P Key
            LSR A
            LSR A
            LSR A
            AND #%10000
            BNE _READKEY

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

                                ; see page 65 in Cody Computer Book
            LDA #3              ; read in row 4 (zero indexed)
            STA VIA_IORA
_READKEY2   LDA VIA_IORA        ; wait for C Key
            LSR A
            LSR A
            LSR A
            AND #%00010
            BNE _READKEY2

            LDA #$04            ; forground color (0=black) backgrund color (4=red)
            STA $D800
            LDA #$05            ; forground color (0=black) backgrund color (5=cyan)
            STA $D801
            LDA #$06            ; forground color (0=black) backgrund color (6=blue)
            STA $D802
            LDA #$07            ; forground color (0=black) backgrund color (7=yellow)
            STA $D803
            LDA #$08            ; forground color (0=black) backgrund color (8=pink)
            STA $D804


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

LAST                            ; End of the entire program

.ENDLOGICAL
