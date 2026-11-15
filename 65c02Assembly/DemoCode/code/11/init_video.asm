INIT_VIDEO_MEM
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
            CPX #144          ; copy 18*8 Bytes
            BNE _COPYCHAR

            LDA #$00
            JSR CLEAR_SCREEN    ; replace all characters with empty character

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
            RTS

INIT_SPRITES
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

            LDA #(80+12)        ; sprite X variable
            STA SPRITEX          
            LDA #(100+21)       ; sprite Y variable
            STA SPRITEY  
            RTS
