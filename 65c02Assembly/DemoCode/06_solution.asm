; draws a level by changing tile colors
; prints a text on a gray status bar at the bottom

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

; set characters from $C400 to $C500 to empty tile
            LDX #0              
_EMPTY0
            STZ $C400,X
            INX
            BNE _EMPTY0
; set characters from $C500 to $C600 to empty tile
            LDX #0              
_EMPTY1
            STZ $C500,X
            INX
            BNE _EMPTY1

; set characters from $C600 to $C700 to empty tile
            LDX #0              
_EMPTY2
            STZ $C600,X
            INX
            BNE _EMPTY2
; set characters from $C700 to $C800 to empty tile
            LDX #0              
_EMPTY3
            STZ $C700,X
            INX
            BNE _EMPTY3

            LDX #0              ; Copy character
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #144          ; copy 18*8 Bytes
            BNE _COPYCHAR
            
            LDA #$00            ; set color pointer to $D800
            STA COLORPTR+0
            LDA #$D8 
            STA COLORPTR+1

            LDX #0              ; Change tile color 
_XLOOP  
            LDY #0              
_COPYCOLOR  LDA #$05            ; forground color (0=black) backgrund color (5=green)
            STA (COLORPTR),Y    ; Copy colors to color memory 
            INY
            CPY #10
            BNE _COPYCOLOR
_COPYCOLOR2 LDA #$0E            ; forground color (0=black) backgrund color (E=light blue)
            STA (COLORPTR),Y    ; Copy colors to color memory 
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

            LDA #$7F            ; Store shared colors (yellow=7 and light gray=15)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

            LDA #1              ; house 0
            STA $C569
            LDA #2              ; house 1
            STA $C56A
            LDA #3              ; house 2
            STA $C56B
            LDA #4              ; house 3
            STA $C56C
            LDA #5              ; house 4
            STA $C56D


;
; start of solution (character copy also changed)
;
            LDX #0              ; Change tile color 
_XLOOP2
            LDY #0              
_COPYCOLOR4 LDA #$0C            ; forground color (0=black) backgrund color (C=gray)
            STA (COLORPTR),Y    ; Copy colors to color memory 
            INY
            CPY #40
            BNE _COPYCOLOR4 

            CLC                 ; Increment color pointer to next row
            LDA COLORPTR+0
            ADC #40
            STA COLORPTR+0
            LDA COLORPTR+1
            ADC #0
            STA COLORPTR+1

            INX                 ; check end of outer loop (5 rows)
            CPX #5
            BNE _XLOOP2 

            LDA #6              ; print C
            STA $C7D0
            LDA #7              ; print o
            STA $C7D1
            LDA #8              ; print d
            STA $C7D2
            LDA #9              ; print y
            STA $C7D3
            LDA #10             ; print v
            STA $C7D4
            LDA #11             ; print i
            STA $C7D5
            LDA #12             ; print s
            STA $C7D6
            LDA #11             ; print i
            STA $C7D7
            LDA #7              ; print o
            STA $C7D8
            LDA #13             ; print n
            STA $C7D9

            LDA #14             ; tree 0
            STA $C6A0
            LDA #15             ; tree 1
            STA $C6A1
            LDA #16             ; tree 2
            STA $C6A2
            LDA #17             ; tree 3
            STA $C6C9

            LDA #$D5            ; set color of upper tree to light green (=D)
            STA $DAA0
            LDA #$D5
            STA $DAA1
            LDA #$D5
            STA $DAA2
            LDA #$95            ; set color of trunk to brown (=9)
            STA $D6A9



_DONE       JMP _DONE           ; Loops forever

CHARDATA

  .BYTE %00000000 ; "empty tile"
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000 ; house tile 0
  .BYTE %00000001
  .BYTE %01010101
  .BYTE %10101010
  .BYTE %10101000
  .BYTE %10101000
  .BYTE %10101010
  .BYTE %00000000

  .Byte %00010101 ; house tile 1
  .Byte %01010101
  .Byte %01010101
  .Byte %10101010
  .Byte %00101010
  .Byte %00101010
  .Byte %10101010
  .Byte %00000000

  .Byte %01010101 ; house tile 2
  .Byte %01010101
  .Byte %01010101
  .Byte %10101010
  .Byte %00001010
  .Byte %00001010
  .Byte %10101010
  .Byte %00000000

  .BYTE %01000000 ; house tile 3
  .BYTE %01010100 
  .BYTE %01010101 
  .BYTE %10101010 
  .BYTE %10000010 
  .BYTE %10000010 
  .BYTE %10101010 
  .Byte %00000000

  .Byte %00000000 ; house tile 4
  .Byte %00000000
  .Byte %01010000
  .Byte %10100000
  .Byte %10100000
  .Byte %10100000
  .Byte %10100000
  .Byte %00000000

  .BYTE %00110000   ; C
  .BYTE %11001100
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11001100
  .BYTE %00110000

  .BYTE %00000000   ; o
  .BYTE %00000000
  .BYTE %00110000
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %00110000

  .BYTE %00001100   ; d
  .BYTE %00001100
  .BYTE %00111100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %00110000

  .BYTE %00000000   ; y
  .BYTE %00000000
  .BYTE %11001100
  .BYTE %11111100
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %00001100
  .BYTE %11111100

  .BYTE %00000000   ; v
  .BYTE %00000000
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %00110000

  .BYTE %11000000   ; i
  .BYTE %00000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %00110000

  .BYTE %00000000   ; s
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00111100
  .BYTE %11000000
  .BYTE %00110000
  .BYTE %00001100
  .BYTE %11110000

  .BYTE %00000000   ; n
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %11110000
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100
  .BYTE %11001100

  .BYTE %00000000 ; tree 0
  .BYTE %00000000
  .BYTE %00000001
  .BYTE %00000001
  .BYTE %00000001
  .BYTE %01010101
  .BYTE %01010101
  .BYTE %00000001

  .BYTE %00010100 ; tree 1 
  .BYTE %00010100 
  .BYTE %01010101 
  .BYTE %01010101 
  .BYTE %01010101 
  .BYTE %01010101 
  .BYTE %01010101 
  .BYTE %01010101 

  .BYTE %00000000 ; tree 2
  .BYTE %00000000
  .BYTE %01000000
  .BYTE %01000000
  .BYTE %01000000
  .BYTE %01010101
  .BYTE %01010101
  .BYTE %01000000

  .BYTE %00101000 ; tree 4 / trunk (mind indentation)
  .BYTE %00101000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

LAST                            ; End of the entire program

.ENDLOGICAL
