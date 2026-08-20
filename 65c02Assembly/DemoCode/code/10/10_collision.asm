; collision between jet and fuel

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
            
            LDA #$0F            ; Sprite bank 0, light gray as common sprite color 
            STA VID_SPRC        ; VID_SPRC=$D006 (see codyconstants.asm)
            LDA #$47            ; yellow=7 color 1, red=4 color 2 (not used in jet sprite)
            STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
            LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
            STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)

            LDA #$40            ; black=0 color 1, red=4 color 2 (not uesed)
            STA SPR0_COL+4      ; 
            LDA #$11            ; sprite data 1 (explode)
            STA SPR0_PTR+4      ;  
            LDA #0              ; invisible
            STA SPR0_X+4        ; 
            LDA #0              ; invisible
            STA SPR0_Y+4        ; 
 
            LDA #$47            ; black=0 color 1 (unused), yellow=7 color 2
            STA SPR0_COL+8      ; 
            LDA #$12            ; sprite data 2 (fire bullet)
            STA SPR0_PTR+8      ;  
            LDA #0              ; invisible
            STA SPR0_X+8        ; 
            LDA #0              ; invisible 
            STA SPR0_Y+8        ; 

            LDA #$6A            ; light red=A color 1, blue=6 color 2
            STA SPR0_COL+12     ; 
            LDA #$13            ; sprite data 3 (fuel)
            STA SPR0_PTR+12     ;  
            LDA #60             ; 
            STA SPR0_X+12       ; 
            LDA #60             ; 
            STA SPR0_Y+12       ;

            LDA #$6C            ; gray=C color 1, blue=6 color 2
            STA SPR0_COL+16     ; 
            LDA #$14            ; sprite data 4 (heli)
            STA SPR0_PTR+16     ;  
            LDA #80             ; 
            STA SPR0_X+16       ; 
            LDA #80             ; 
            STA SPR0_Y+16       ;

            LDA #$6A            ; light red=A color 1, blue=6 color 2
            STA SPR0_COL+20     ; 
            LDA #$15            ; sprite data 5 (plane)
            STA SPR0_PTR+20     ;  
            LDA #100          ; 
            STA SPR0_X+20       ; 
            LDA #40             ; 
            STA SPR0_Y+20       ;  

            LDA #$6A            ; light red=A color 1, blue=6 color 2
            STA SPR0_COL+24     ; 
            LDA #$16            ; sprite data 6 (ship)
            STA SPR0_PTR+24     ;  
            LDA #110          ; 
            STA SPR0_X+24       ; 
            LDA #100          ; 
            STA SPR0_Y+24       ;

            LDA #$6A            ; light red=A color 1, blue=6 color 2
            STA SPR0_COL+28     ; 
            LDA #$16            ; sprite data 6 (ship)
            STA SPR0_PTR+28     ;  
            LDA #60             ; 
            STA SPR0_X+28       ; 
            LDA #130          ; 
            STA SPR0_Y+28       ;   

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
            JSR CHECK_COLLISION
            JSR WAITBLANK       ; Wait for the next frame

            LDA SPRITEX         ; sprite X
            STA SPR0_X          ; SPR0_X=$D080 (see codyconstants.asm)
            LDA SPRITEY         ; sprite Y
            STA SPR0_Y          ; SPR0_Y=$D081 (see codyconstants.asm)

            JMP _LOOP           ; Game loops 

CHECK_COLLISION
    ; Check if fuel is too far left
    CLC
    LDA SPR0_X        
    SBC SPR0_X+12     ; jet_x - fuel_x
    CMP #5            ; fuel width-1
    BPL _NO_COLLISION

    ; Check if fuel is too far right
    CLC
    LDA SPR0_X+12
    SBC SPR0_X        ; fuel_x - jet_x
    CMP #6            ; jet width-1
    BPL _NO_COLLISION 

    ; Check if fuel is too far up
    CLC
    LDA SPR0_Y
    SBC SPR0_Y+12     ; jet_y - fuel_y
    CMP #19           ; fuel height-1
    BPL _NO_COLLISION

    ; Check if fuel is too far down
    CLC
    LDA SPR0_Y+12
    SBC SPR0_Y        ; fuel_y - jet_y
    CMP #13           ; jet height-1 
    BPL _NO_COLLISION
    JMP _COLLISION_DETECTED
_NO_COLLISION
    LDA #$47            ; change color to yellow (=7)
    STA SPR0_COL 
    RTS
_COLLISION_DETECTED
    LDA #$74            ; change color to red (=4)
    STA SPR0_COL 
    RTS

WAITBLANK

_WAITVIS    LDA VID_BLNK        ; Wait until the blanking is zero (drawing the screen)
            BNE _WAITVIS
            
_WAITBLANK  LDA VID_BLNK        ; Wait until the blanking is one (not drawing the screen)
            BEQ _WAITBLANK
            
            RTS

SPRITEDATA

; Jet sprite data
.BYTE %00_00_00_01, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_01, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_01, %00_00_00_00, %00_00_00_00
.BYTE %00_00_01_01, %01_00_00_00, %00_00_00_00
.BYTE %00_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_01_01, %01_01_01_00, %00_00_00_00
.BYTE %01_01_00_01, %00_01_01_00, %00_00_00_00
.BYTE %01_00_00_01, %00_00_01_00, %00_00_00_00
.BYTE %00_00_00_01, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_01, %00_00_00_00, %00_00_00_00
.BYTE %00_00_01_01, %01_00_00_00, %00_00_00_00
.BYTE %00_01_01_01, %01_01_00_00, %00_00_00_00
.BYTE %00_01_00_01, %00_01_00_00, %00_00_00_00
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

; fire bullet
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00 
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %01_00_00_00, %00_00_00_00, %00_00_00_00
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
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

; fuel
.BYTE %00_00_01_01, %01_00_00_00, %00_00_00_00
.BYTE %01_01_10_10, %10_01_00_00, %00_00_00_00
.BYTE %01_01_10_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_10_10, %01_01_00_00, %00_00_00_00
.BYTE %01_01_10_01, %01_01_00_00, %00_00_00_00
.BYTE %11_11_11_11, %11_11_00_00, %00_00_00_00
.BYTE %11_11_10_11, %10_11_00_00, %00_00_00_00
.BYTE %11_11_10_11, %10_11_00_00, %00_00_00_00
.BYTE %11_11_10_10, %10_11_00_00, %00_00_00_00
.BYTE %11_11_11_11, %11_11_00_00, %00_00_00_00
.BYTE %01_01_10_10, %10_01_00_00, %00_00_00_00
.BYTE %01_01_10_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_10_10, %10_01_00_00, %00_00_00_00
.BYTE %01_01_10_01, %01_01_00_00, %00_00_00_00
.BYTE %01_01_10_10, %10_01_00_00, %00_00_00_00
.BYTE %11_11_11_11, %11_11_00_00, %00_00_00_00
.BYTE %11_11_10_11, %11_11_00_00, %00_00_00_00
.BYTE %11_11_10_11, %11_11_00_00, %00_00_00_00
.BYTE %11_11_10_10, %10_11_00_00, %00_00_00_00
.BYTE %11_11_11_11, %11_11_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

SPRITEDATA2

; heli
.BYTE %00_00_01_01, %01_00_00_00, %00_00_00_00
.BYTE %01_01_01_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_01_00, %00_00_00_00, %00_00_00_00
.BYTE %11_11_11_11, %11_00_00_00, %11_00_00_00
.BYTE %10_10_10_10, %10_10_10_10, %10_00_00_00
.BYTE %00_00_11_00, %00_00_00_00, %11_00_00_00
.BYTE %00_11_11_11, %00_00_00_00, %00_00_00_00
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
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

; plane
.BYTE %00_00_00_00, %00_00_00_00, %10_10_00_00
.BYTE %00_10_10_00, %00_00_00_10, %10_10_00_00
.BYTE %11_11_11_11, %11_11_11_11, %11_11_00_00
.BYTE %11_11_11_11, %00_00_00_11, %11_00_00_00
.BYTE %00_00_00_11, %11_11_11_00, %00_00_00_00
.BYTE %00_00_00_00, %11_11_11_00, %00_00_00_00
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
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

; ship
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
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00

; ship (TODO remove placeholder)
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
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00 
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
.BYTE %00_00_00_00, %00_00_00_00, %00_00_00_00
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
