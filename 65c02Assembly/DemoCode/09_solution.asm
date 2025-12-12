; livel with 8 sprites

.include "codyconstants.asm"

SPRITEX = $D0
SPRITEY = $D1
COLORPTR = $D2

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

; start of solution
            LDX #0              ; Copy sprite data into video memory (4 sprites of 64 byte)
_COPYSPRT   LDA SPRITEDATA,X
            STA $A400,X         ; sprite pixel data location. Page 327 and 535 
            INX
            CPX #255
            BNE _COPYSPRT

            LDX #0              ; Copy sprite data into video memory (4 sprites of 64 byte)
_COPYSPRT2  LDA SPRITEDATA2,X
            STA $A500,X         ; sprite pixel data location. Page 327 and 535 
            INX
            CPX #255
            BNE _COPYSPRT2


; end of solution
            
            LDA #$0F            ; Sprite bank 0, light gray as common sprite color 
            STA VID_SPRC        ; VID_SPRC=$D006 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in jet sprite)
            STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
            LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
            STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)

; start of solution

            LDA #$40            ; black=0 color 1, red=4 color 2
            STA SPR0_COL+4      ; 
            LDA #$11            ; sprite data 1 (house left)
            STA SPR0_PTR+4      ;  
            LDA #12             ; 
            STA SPR0_X+4        ; 
            LDA #60             ; 
            STA SPR0_Y+4        ; 

            LDA #$40            ; black=0 color 1, red=4 color 2 (not uesed)
            STA SPR0_COL+8      ; 
            LDA #$12            ; sprite data 2 (house right)
            STA SPR0_PTR+8      ;  
            LDA #24             ; 
            STA SPR0_X+8        ; 
            LDA #60             ; 
            STA SPR0_Y+8        ;

            LDA #$40            ; black=0 color 1, red=4 color 2 (not uesed)
            STA SPR0_COL+12     ; 
            LDA #$13            ; sprite data 3 (explode)
            STA SPR0_PTR+12     ;  
            LDA #0              ; invisible
            STA SPR0_X+12       ; 
            LDA #0              ; invisible
            STA SPR0_Y+12       ; 
 

            LDA #$47            ; black=0 color 1 (unused), yellow=7 color 2
            STA SPR0_COL+16     ; 
            LDA #$14            ; sprite data 4 (fire)
            STA SPR0_PTR+16     ;  
            LDA #0              ; invisible
            STA SPR0_X+16       ; 
            LDA #0              ; invisible 
            STA SPR0_Y+16       ; 

            LDA #$6A            ; light red=A color 1, blue=6 color 2
            STA SPR0_COL+20     ; 
            LDA #$15            ; sprite data 5 (fuel)
            STA SPR0_PTR+20     ;  
            LDA #60             ; 
            STA SPR0_X+20       ; 
            LDA #60             ; 
            STA SPR0_Y+20       ;

            LDA #$6C            ; gray=C color 1, blue=6 color 2
            STA SPR0_COL+24     ; 
            LDA #$16            ; sprite data 6 (heli)
            STA SPR0_PTR+24     ;  
            LDA #80             ; 
            STA SPR0_X+24       ; 
            LDA #80             ; 
            STA SPR0_Y+24       ;

            LDA #$6A            ; light red=A color 1, blue=6 color 2
            STA SPR0_COL+28     ; 
            LDA #$17            ; sprite data 7 (plane)
            STA SPR0_PTR+28     ;  
            LDA #100          ; 
            STA SPR0_X+28       ; 
            LDA #40             ; 
            STA SPR0_Y+28       ;  

; end of solution

            LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
            STA VIA_DDRA
            LDA #$06            ; Set VIA to read joystick 1
            STA VIA_IORA

            LDA #(80+12)        ; sprite X variable
            STA SPRITEX          
            LDA #(100+21)       ; sprite Y variable
            STA SPRITEY   

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
            CPX #20
            BNE _XLOOP

;
; start of solution
;
            LDX #0              ; Change tile color 
_XLOOP2
            LDY #0              
_COPYCOLOR4 LDA #$0C            ; forground color (0=black) backgrund color (5=gray)
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

            LDX #0              ; Copy character
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #72             ; 9*8=40
            BNE _COPYCHAR


            LDA #$72            ; Store shared colors (light blue=14 and red=2)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

            LDA #1              ; print C
            STA $C7D0
            LDA #2              ; print o
            STA $C7D1
            LDA #3              ; print d
            STA $C7D2
            LDA #4              ; print y
            STA $C7D3
            LDA #5              ; print v
            STA $C7D4
            LDA #6              ; print i
            STA $C7D5
            LDA #7              ; print s
            STA $C7D6
            LDA #6              ; print i
            STA $C7D7
            LDA #2              ; print o
            STA $C7D8
            LDA #8              ; print n
            STA $C7D9              

_LOOP      
            LDA VIA_IORA        ; Read joystick
            LSR A
            LSR A
            LSR A
            
            BIT #8              ; Joystick right
            BEQ _RIGHT
            
            BIT #4              ; Joystick left
            BEQ _LEFT

            BIT #2              ; Joystick down 
            BEQ _DOWN
            
            BIT #1              ; Joystick up 
            BEQ _UP

            JMP _DRAW

_RIGHT      INC SPRITEX         ; SPRITEX++
            JMP _DRAW
_LEFT       DEC SPRITEX         ; SPRITEX--
            JMP _DRAW
_DOWN       INC SPRITEY         ; SPRITEY++
            JMP _DRAW
_UP         DEC SPRITEY         ; SPRITEY--
            JMP _DRAW
_DRAW
            JSR WAITBLANK       ; Wait for the next frame

            LDA SPRITEX         ; sprite X
            STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
            LDA SPRITEY         ; sprite Y
            STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)

            JMP _LOOP           ; Game loops 


WAITBLANK

_WAITVIS    LDA VID_BLNK        ; Wait until the blanking is zero (drawing the screen)
            BNE _WAITVIS
            
_WAITBLANK  LDA VID_BLNK        ; Wait until the blanking is one (not drawing the screen)
            BEQ _WAITBLANK
            
            RTS

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

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; house left
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %01_01_01_01
.BYTE %00_00_00_00, %00_00_01_01, %01_01_01_01
.BYTE %00_00_00_01, %01_01_01_01, %01_01_01_01
.BYTE %00_00_00_11, %11_11_11_11, %11_11_11_11
.BYTE %00_00_00_11, %11_11_00_00, %11_11_11_00
.BYTE %00_00_00_11, %11_11_00_00, %11_11_11_00
.BYTE %00_00_00_11, %11_11_11_11, %11_11_11_11
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; house right
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %00_00_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %01_00_00_00
.BYTE %11_11_11_11, %11_11_11_11, %11_00_00_00
.BYTE %00_11_11_11, %00_00_11_11, %11_00_00_00
.BYTE %00_11_11_11, %00_00_11_11, %11_00_00_00
.BYTE %11_11_11_11, %11_11_11_11, %11_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; explode 
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %11_00_00_00, %11_00_11_00
.BYTE %00_00_00_00, %00_00_11_00, %00_00_00_00
.BYTE %00_00_11_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_11_00_00, %11_00_00_00
.BYTE %00_00_00_01, %00_00_00_00, %00_00_01_00
.BYTE %00_00_00_00, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_10_00, %00_00_00_00, %00_10_00_00
.BYTE %00_00_00_00, %00_10_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

SPRITEDATA2

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; fire
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_01_01_01, %00_00_00_00 ; fuel
.BYTE %00_00_00_01, %01_10_10_10, %01_00_00_00
.BYTE %00_00_00_01, %01_10_01_01, %01_00_00_00
.BYTE %00_00_00_01, %01_10_10_01, %01_00_00_00
.BYTE %00_00_00_01, %01_10_01_01, %01_00_00_00
.BYTE %00_00_00_11, %11_11_11_11, %11_00_00_00
.BYTE %00_00_00_11, %11_10_11_10, %11_00_00_00
.BYTE %00_00_00_11, %11_10_11_10, %11_00_00_00
.BYTE %00_00_00_11, %11_10_10_10, %11_00_00_00
.BYTE %00_00_00_11, %11_11_11_11, %11_00_00_00
.BYTE %00_00_00_01, %01_10_10_10, %01_00_00_00
.BYTE %00_00_00_01, %01_10_01_01, %01_00_00_00
.BYTE %00_00_00_01, %01_10_10_10, %01_00_00_00
.BYTE %00_00_00_01, %01_10_01_01, %01_00_00_00
.BYTE %00_00_00_01, %01_10_10_10, %01_00_00_00
.BYTE %00_00_00_11, %11_11_11_11, %11_00_00_00
.BYTE %00_00_00_11, %11_10_11_11, %11_00_00_00
.BYTE %00_00_00_11, %11_10_11_11, %11_00_00_00
.BYTE %00_00_00_11, %11_10_10_10, %11_00_00_00
.BYTE %00_00_00_11, %11_11_11_11, %11_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; heli
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_01_01_00, %00_00_00_00
.BYTE %00_00_01_01, %01_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %01_00_00_00, %00_00_00_00
.BYTE %00_00_11_11, %11_11_11_00, %00_00_11_00
.BYTE %00_00_10_10, %10_10_10_10, %10_10_10_00
.BYTE %00_00_00_00, %11_00_00_00, %00_00_11_00
.BYTE %00_00_00_11, %11_11_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; plane
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_10_10_00
.BYTE %00_00_10_10, %00_00_00_00, %10_10_10_00
.BYTE %00_11_11_11, %11_11_11_11, %11_11_11_00
.BYTE %00_11_11_11, %11_00_00_00, %11_11_00_00
.BYTE %00_00_00_00, %11_11_11_11, %00_00_00_00
.BYTE %00_00_00_00, %00_11_11_11, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; ship
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_10, %10_00_00_00, %00_00_00_00
.BYTE %00_00_10_10, %10_00_00_00, %00_00_00_00
.BYTE %00_10_10_10, %10_10_10_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_01, %01_01_01_01
.BYTE %01_01_01_01, %01_01_01_01, %01_01_00_00
.BYTE %00_11_11_11, %11_11_11_11, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 ; tree
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_10_10_00, %00_00_00_00
.BYTE %00_00_00_00, %00_10_10_00, %00_00_00_00
.BYTE %00_00_00_00, %00_10_10_00, %00_00_00_00
.BYTE %00_00_00_10, %10_10_10_10, %10_00_00_00
.BYTE %00_00_00_10, %10_10_10_10, %10_00_00_00
.BYTE %00_00_00_10, %10_10_10_10, %10_00_00_00
.BYTE %10_10_10_10, %10_10_10_10, %10_10_10_10
.BYTE %10_10_10_10, %10_10_10_10, %10_10_10_10
.BYTE %00_00_00_10, %10_10_10_10, %10_00_00_00
.BYTE %00_00_00_00, %00_01_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_01_01_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

CHARDATA

  .BYTE %00000000   ; "empty tile"
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

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

LAST                            ; End of the entire program

.ENDLOGICAL
