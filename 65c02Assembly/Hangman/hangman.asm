.include "codyconstants.asm"

; Zero Page

CURSOR_X = $D0          ; location of the next Letter to be printed 
KEY_PRESSED = $D1       ; codscii value of the pressed key
WRONG_LETTERS = $D2     ; inc every time the letters is not part of the word
SECRET_WORD_LEN = $D3
RANDOM_VALUE = $D4      ; TODO 

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

            ; prints string in 'Text0'
            LDX #0
_Print_Word_Len_Text 
            LDA Text0, X
            STA $C428, X  
            INX
            CPX #9
            BNE _Print_Word_Len_Text

            ; prints string in 'Text1'
            LDX #0
_Print_Tried_Text
            LDA Text1, X
            STA $C4A0, X  
            INX
            CPX #10
            BNE _Print_Tried_Text

            ; First letter will be printed $C484+CURSOR_X (see below)
            LDA #$01
            STA CURSOR_X

            ; no wrong letters entered at game start
            LDA #$00
            STA WRONG_LETTERS

            ; remember number of letters
            LDA WORD_LENGTH
            STA SECRET_WORD_LEN

            ; print number of letters (only works for word length <10)
            CLC
            ADC #48  ; '0' char starts at codscii value 48
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

.include "graphics.asm"
.include "key_input.asm"

Text0 .TEXT "WORD LEN:"
Text1 .TEXT "YOU TRIED:"
WORD_LENGTH .BYTE 7
Word0 .TEXT "HANGMAN"

LAST                            ; End of the entire program

.ENDLOGICAL
