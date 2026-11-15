DRAW_LEVEL
            LDA #$7F            ; Store shared colors (yellow=7 and light gray=15)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

            LDA #$00            ; set color pointer to $D800
            STA COLORPTR+0
            LDA #$D8 
            STA COLORPTR+1
            
            LDX #0              ; Change tile color 
_DRAW_LEVEL  
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
            BNE _DRAW_LEVEL

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

            RTS

; draws the status bar
DRAW_STATUS_BAR
            LDX #0              ; Change tile color 
_DRAW_STATUS_BAR
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
            BNE _DRAW_STATUS_BAR 

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
            RTS
