.include "codyconstants.asm"

; Zero Page

CURSOR_X = $D0          ; location of the next Letter to be printed 
KEY_PRESSED = $D1       ; codscii value of the pressed key
WRONG_LETTERS = $D2     ; inc every time the letters is not part of the word
SECRET_WORD_LEN = $D3 

; CONSTANTS where to print
WORD_PRINT_START = $C478
LETTER_PRINT_START = $C4AA

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
            LDA #$C9            ; Store shared colors (gray=14 and brown=9)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm) 

            JSR LOAD_CODSCII_TO_CHAR_MEM
            LDA #$2C            ; clear with red=2 and gray=C 
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            LDX #0
_Print_Instructions 
            LDA Text0, X
            STA $C428, X  
            INX
            CPX #9
            BNE _Print_Instructions

            LDX #0
_Print_Tried 
            LDA Text1, X
            STA $C4A0, X  
            INX
            CPX #10
            BNE _Print_Tried

            ; First letter will be printed $C484+CURSOR_X
            LDA #$01
            STA CURSOR_X

            ; no wrong letters entered at game start
            LDA #$00
            STA WRONG_LETTERS

            ; remember number of letters
            LDA #$07
            STA SECRET_WORD_LEN

            ; print number of letters (only works for word length <10)
            CLC
            ADC #48  ; 0 starts at codscii value 48
            STA $C432


_GAME_LOOP
        ; TODO: wait blank and draw hangman       
        JSR KEY_TO_A
        BEQ _GAME_LOOP
        ; key was pressed and codscii value is in A 
        STA KEY_PRESSED

        ; check if letter was entered before by iterating 
        ; from LETTER_PRINT_START to LETTER_PRINT_START+X
        LDX #$00
 _CHECK_ALREADY_PRESSED
        LDA LETTER_PRINT_START, X
        CMP KEY_PRESSED
        BEQ _NO_NEW_LETTER_ENTERED
        INX
        CPX CURSOR_X
        BNE _CHECK_ALREADY_PRESSED

        ; print key (codscii value) at LETTER_PRINT_START+X
        LDX CURSOR_X
        LDA KEY_PRESSED
        STA LETTER_PRINT_START, X

        ; CURSOR_X++
        TXA
        INC A
        STA CURSOR_X

        ; Check if letter in word
        LDY #$00 ; Y=false, letter not in word
        LDX #$00
  _CHECK_IF_IN_WORD
        LDA KEY_PRESSED
        CMP Word0, X
        BNE _NO_LETTER_MATCH
        STA WORD_PRINT_START, X ; print letter at correct location of secret word
        LDY #$01 ; Y=true, letter in word
  _NO_LETTER_MATCH
        INX
        CPX SECRET_WORD_LEN
        BNE _CHECK_IF_IN_WORD

        CPY #$00
        BEQ _LETTER_NOT_IN_WORD
        ; TODO: check if won if Y=true
        JMP _GAME_LOOP
        

_LETTER_NOT_IN_WORD
        ; new letter and not in word
        LDA WRONG_LETTERS
        INC A
        STA WRONG_LETTERS


 _NO_NEW_LETTER_ENTERED


        JMP _GAME_LOOP           ; Loops forever

; loads the ASCII value of a Key to A register
; TODO: improve performance
KEY_TO_A
        LDA #0
        STA VIA_IORA
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%10000
        BNE _NEXT_KEY0
        LDA #"O"
        RTS
_NEXT_KEY0
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%01000
        BNE _NEXT_KEY1
        LDA #"U"
        RTS
_NEXT_KEY1
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00100
        BNE _NEXT_KEY2
        LDA #"T"
        RTS
_NEXT_KEY2
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00010
        BNE _NEXT_KEY3
        LDA #"E"
        RTS
_NEXT_KEY3
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00001
        BNE _NEXT_KEY4
        LDA #"Q"
        RTS
_NEXT_KEY4

        LDA #1
        STA VIA_IORA
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%10000
        BNE _NEXT_KEY5
        LDA #"L"
        RTS
_NEXT_KEY5
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%01000
        BNE _NEXT_KEY6
        LDA #"J"
        RTS
_NEXT_KEY6
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00100
        BNE _NEXT_KEY7
        LDA #"G"
        RTS
_NEXT_KEY7
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00010
        BNE _NEXT_KEY8
        LDA #"D"
        RTS
_NEXT_KEY8
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00001
        BNE _NEXT_KEY9
        LDA #"A"
        RTS
_NEXT_KEY9

        LDA #2
        STA VIA_IORA
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%10000
        BNE _NEXT_KEY10
        LDA #$00 ; TODO: support META
        RTS
_NEXT_KEY10
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%01000
        BNE _NEXT_KEY11
        LDA #"N"
        RTS
_NEXT_KEY11
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00100
        BNE _NEXT_KEY12
        LDA #"V"
        RTS
_NEXT_KEY12
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00010
        BNE _NEXT_KEY13
        LDA #"X"
        RTS
_NEXT_KEY13
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00001
        BNE _NEXT_KEY14
        LDA #$00 ; TODO: support CODY
        RTS
_NEXT_KEY14 

        LDA #3
        STA VIA_IORA
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%10000
        BNE _NEXT_KEY16
        LDA #$00 ; TODO: support ARROW
        RTS
_NEXT_KEY16 ; TODO: fix off-by one
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%01000
        BNE _NEXT_KEY17
        LDA #"M"
        RTS
_NEXT_KEY17
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00100
        BNE _NEXT_KEY18
        LDA #"B"
        RTS
_NEXT_KEY18
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00010
        BNE _NEXT_KEY19
        LDA #"C"
        RTS
_NEXT_KEY19
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00001
        BNE _NEXT_KEY20
        LDA #"Z" 
        RTS
_NEXT_KEY20

        LDA #4
        STA VIA_IORA
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%10000
        BNE _NEXT_KEY21
        LDA #$00 ; TODO: support SPACE
        RTS
_NEXT_KEY21
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%01000
        BNE _NEXT_KEY22
        LDA #"K"
        RTS
_NEXT_KEY22
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00100
        BNE _NEXT_KEY23
        LDA #"H"
        RTS
_NEXT_KEY23
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00010
        BNE _NEXT_KEY24
        LDA #"F"
        RTS
_NEXT_KEY24
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00001
        BNE _NEXT_KEY25
        LDA #"S" 
        RTS
_NEXT_KEY25

        LDA #5
        STA VIA_IORA
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%10000
        BNE _NEXT_KEY26
        LDA #"P"
        RTS
_NEXT_KEY26
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%01000
        BNE _NEXT_KEY27
        LDA #"I"
        RTS
_NEXT_KEY27
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00100
        BNE _NEXT_KEY28
        LDA #"Y"
        RTS
_NEXT_KEY28
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00010
        BNE _NEXT_KEY29
        LDA #"R"
        RTS
_NEXT_KEY29
        LDA VIA_IORA        
        LSR A
        LSR A
        LSR A
        AND #%00001
        BNE _NO_KEY
        LDA #"W" 
        RTS
_NO_KEY
        LDA #$00 ; nothing
        RTS

.include "graphics.asm"

Text0 .TEXT "WORD LEN:"
Text1 .TEXT "YOU TRIED:"
Word0 .TEXT "HANGMAN"

LAST                            ; End of the entire program

.ENDLOGICAL
