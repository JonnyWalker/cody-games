.include "codyconstants.asm"

; Zero page variables

CURSOR_X = $D0          ; location of the next letter to be printed 
KEY_PRESSED = $D1       ; codscii value of the pressed key
WRONG_LETTERS = $D2     ; inc every time the letters is not part of the word
SECRET_WORD_LEN = $D3
RANDOM_VALUE = $D4      ; used to select a random word
WORD_PTR = $D5          ; 2 BYTES Pointer in word string according to random value
SECRET_WORD = $D7       ; start of secrect word, will be filled later

; CONSTANTS: where to print and other stuff
WORD_PRINT_START = $C478
LETTER_PRINT_START = $C4AA
BLANK_CHAR = #$00
MAX_MISTAKES = #$05

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

; print text of length at (row, column)
PRINT .macro text, column, row, length
    LDX #0
 _Print_Text
    LDA \text, X
    STA 50176+\column+\row*40, X  ;50176=$C400
    INX
    CPX #\length
    BNE _Print_Text
    .endmacro
      
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

; show instruction screen, compute random value and wait for space key
_TITLE_SCREEN
            LDA #$2C            ; clear with red=2 and gray=C 
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            ; prints "HANGMAN"
            #PRINT Text4, 0, 1, 7
            ; prints "GUESS A WORD BY TYPING LETTERS."
            #PRINT Text5, 0, 2, 31

 _NEXT_GAME ; game loop jumps back here after game end
            
            ; prints "PRESS SPACE TO CONTINUE."
            #PRINT Text6, 0, 23, 24

    _WAIT_FOR_SPACE
            ; compute random value between 0 and 255
            LDA RANDOM_VALUE
            INC A
            STA RANDOM_VALUE

            ; exit loop on space key
            JSR KEY_TO_A
            CMP #$20
            BNE _WAIT_FOR_SPACE 

_NEW_GAME
            ; loop moves word pointer to word of random value
            ; SECRET_WORD_LEN and WORD_PTR should match after the loop
            
            ; Start word pointer at beginning of 'Words' (see at end of file)
            LDA #<Words       
            STA WORD_PTR+0
            LDA #>Words
            STA WORD_PTR+1 
            LDX #$00
 _MOVE_WORD_PTR
            ; remember word length of word X
            LDA WORD_LENGTH, X
            STA SECRET_WORD_LEN

            ; Check if we have moved the pointer RANDOM_VALUE-times and exit if true
            CPX RANDOM_VALUE
            BEQ _WORD_POINTER_DONE

            ; WORD_PTR += WORD_LENGTH[X]
            CLC                
            LDA WORD_PTR+0
            ADC WORD_LENGTH, X
            STA WORD_PTR+0
            LDA WORD_PTR+1
            ADC #0
            STA WORD_PTR+1

            ; otherwise loop again and X++
            INX
            JMP _MOVE_WORD_PTR
 _WORD_POINTER_DONE 

            LDA #$2C            ; clear with red=2 and gray=C 
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            ; prints "WORD LEN:"
            #PRINT Text0, 0, 1, 9

            ; prints "YOU TRIED:"
            #PRINT Text1, 0, 4, 10

            ; First letter will be printed $C484+CURSOR_X (see below)
            LDA #$01
            STA CURSOR_X

            ; no wrong letters entered at game start
            LDA #$00
            STA WRONG_LETTERS

            ; copy WORD_PTR[X] to SECRET_WORD zero page variable
            LDY #$00
 _COPY_TO_SECRET_WORD
            LDA (WORD_PTR), Y
            STA SECRET_WORD, Y
            INY
            CPY SECRET_WORD_LEN
            BNE _COPY_TO_SECRET_WORD

            ; print number of letters
            ; TODO(BUG): only works for word length <10
            LDA SECRET_WORD_LEN
            CLC
            ADC #48  ; '0' char starts at codscii value 48
            STA $C432

_GAME_LOOP
        ; TODO: wait blank and draw hangman according to WRONG_LETTERS
        JSR WAITBLANK

        JSR KEY_TO_A
        BEQ _GAME_LOOP
        CMP #$20        ; SPACE KEY
        BEQ _GAME_LOOP
        ; letter key was pressed and codscii value is in A 
        STA KEY_PRESSED

        ; loop: check if letter was entered before by iterating 
        ; from LETTER_PRINT_START to LETTER_PRINT_START+X
        LDX #$00
 _CHECK_ALREADY_PRESSED
        LDA LETTER_PRINT_START, X
        CMP KEY_PRESSED
        BEQ _NO_NEW_LETTER_ENTERED ; skip everything below
        INX
        CPX CURSOR_X
        BNE _CHECK_ALREADY_PRESSED
        ; new letter entered

        ; print key/letter (codscii value) at LETTER_PRINT_START+X
        LDX CURSOR_X
        LDA KEY_PRESSED
        STA LETTER_PRINT_START, X

        ; CURSOR_X++
        TXA
        INC A
        STA CURSOR_X

        ; loop: Check if letter in secrect word by iterating over the secret word
        LDY #$00 ; Y=false, letter not in word
        LDX #$00
 _CHECK_IF_IN_WORD
        LDA KEY_PRESSED
        CMP SECRET_WORD, X
        BNE _NO_LETTER_MATCH
        STA WORD_PRINT_START, X ; print letter at correct location of secret word
        LDY #$01 ; Y=true, letter in word
 _NO_LETTER_MATCH
        INX
        CPX SECRET_WORD_LEN
        BNE _CHECK_IF_IN_WORD

        CPY #$00
        BEQ _LETTER_NOT_IN_WORD

        ; check if won by searching for blank chars
        LDY #$01 ; Y = true = won
        LDX #$00
 _CHECK_WON
        LDA BLANK_CHAR
        CMP WORD_PRINT_START, X
        BNE _NO_BLANK
        LDY #$00 ; Blank Char found: Y = false = not won
 _NO_BLANK
        INX 
        CPX SECRET_WORD_LEN
        BNE _CHECK_WON

        ; skip won message if Y=false
        CPY #$00
        BEQ _NOT_WON

        ; prints "YOU WON!"
        #PRINT Text2, 0, 5, 8

        JMP _NEXT_GAME

 _NOT_WON        
        JMP _GAME_LOOP
        
 _LETTER_NOT_IN_WORD
        ; new letter and not in word: WRONG_LETTERS++
        LDA WRONG_LETTERS
        INC A
        STA WRONG_LETTERS

        ; check game over state: WRONG_LETTERS==MAX_MISTAKES
        CMP MAX_MISTAKES
        BNE _NOT_GAME_OVER

        ; prints "YOU LOSE!"
        #PRINT Text3, 0, 5, 9

        JMP _NEXT_GAME

 _NOT_GAME_OVER


 _NO_NEW_LETTER_ENTERED
        JMP _GAME_LOOP           ; End of main game loop    

.include "graphics.asm"
.include "key_input.asm"

Text0 .TEXT "WORD LEN:"
Text1 .TEXT "YOU TRIED:"
Text2 .TEXT "YOU WON!"
Text3 .TEXT "YOU LOSE!"
Text4 .TEXT "HANGMAN"
Text5 .TEXT "GUESS A WORD BY TYPING LETTERS."
Text6 .TEXT "PRESS SPACE TO CONTINUE."
WORD_LENGTH .BYTE 6, 3, 3, 6, 6, 5, 3, 4, 4, 4, 4, 3, 4, 4, 5, 4, 4, 4, 4, 6, 3, 3, 7, 8, 8, 4, 7, 4, 3, 5, 4, 6, 7, 6, 6, 5, 5, 6, 6, 4, 5, 7, 5, 5, 5, 7, 9, 4, 4, 6, 7, 6, 3, 5, 3, 10, 9, 8, 6, 6, 4, 3, 5, 3, 6, 7, 10, 3, 4, 6, 3, 4, 5, 4, 10, 5, 5, 4, 4, 3, 4, 5, 4, 7, 4, 4, 5, 4, 5, 3, 4, 4, 8, 11, 6, 8, 4, 6, 3, 3, 4, 4, 8, 3, 3, 5, 3, 4, 5, 4, 4, 7, 3, 3, 8, 4, 6, 4, 4, 4, 6, 5, 5, 4, 5, 5, 6, 5, 4, 4, 6, 6, 5, 6, 3, 4, 4, 5, 9, 4, 4, 5, 4, 4, 6, 5, 9, 7, 7, 8, 8, 4, 5, 4, 6, 6, 6, 4, 5, 4, 4, 3, 4, 4, 6, 7, 3, 4, 6, 8, 3, 4, 4, 6, 4, 4, 4, 7, 8, 3, 6, 6, 4, 5, 4, 6, 7, 5, 3, 7, 5, 3, 7, 6, 4, 6, 6, 5, 4, 5, 4, 7, 9, 11, 8, 6, 7, 3, 6, 5, 4, 7, 8, 10, 4, 8, 3, 8, 5, 4, 5, 8, 6, 8, 8, 8, 4, 8, 5, 7, 6, 7, 5, 7, 9, 8, 9, 7, 11, 6, 8, 6, 8, 8, 7, 6, 6, 8, 8, 5, 7, 7, 4, 6, 4
Words .TEXT "ACTIONAGEAIRANIMALANSWERAPPLEARTBABYBACKBALLBANKBEDBILLBIRDBLOODBOATBODYBONEBOOKBOTTOMBOXBOYBROTHERBUILDINGBUSINESSCALLCAPITALCASECATCAUSECENTCENTERCENTURYCHANCECHANGECHECKCHILDCHURCHCIRCLECITYCLASSCLOTHESCLOUDCOASTCOLORCOMPANYCONSONANTCODYCORNCOTTONCOUNTRYCOURSECOWCROWDDAYDICTIONARYDIRECTIONDISTANCEDOCTORDOLLARDOOREAREARTHEGGENERGYEXAMPLEEXPERIENCEEYEGAMEGARDENGASGIRLGLASSGOLDGOVERNMENTGRASSGROUPHAIRHANDHATHEADHEARTHEATHISTORYHOLEHOMEHORSEHOURHOUSEICEIDEAINCHINDUSTRYINFORMATIONINSECTINTERESTIRONISLANDJOBKEYLAKELANDLANGUAGELAWLEGLEVELLIELIFELIGHTLINELISTMACHINEMANMAPMATERIALMEATMIDDLEMILEMILKMINDMINUTEMONEYMONTHMOONMOUTHMUSICNATIONNIGHTNOSENOTENUMBEROBJECTOCEANOFFICEOILPAGEPAIRPAPERPARAGRAPHPARKPARTPARTYPASTPOSTPERSONPOUNDPRESIDENTPROBLEMPRODUCTPROPERTYQUESTIONRACERADIORAINREASONRECORDREGIONRINGRIVERROADROCKROWRULESANDSCHOOLSCIENCESEASEATSECONDSENTENCESETSIDESIGNSISTERSIZESKINSNOWSOLDIERSOLUTIONSONSPRINGSQUARESTARSTATESTOPSTREETSTUDENTSUGARSUNVILLAGEVOWELWARWEATHERWEIGHTWIFEWINDOWWINTERWOMANWORDWORLDYEARACCOUNTALGORITHMAPPLICATIONEXPLORERBACKUPBROWSERBUGCLIENTCLOUDCODECOMMANDCOMPUTERCONNECTIONDATADATABASESQLDOWNLOADERRORFILELINUXFIREWALLFOLDERFUNCTIONHARDWAREINTERNETDISKKEYBOARDLOGINWINDOWSMEMORYMONITORMOUSENETWORKMACINTOSHPASSWORDPROCESSORPROGRAMPROGRAMMINGSCREENSECURITYSERVERSOFTWARECOMPILERSTORAGEUPDATEUPLOADUSERNAMEVARIABLEVIRUSWEBSITEHANGMANJAVAPYTHONRUST"

LAST         ; End of the entire program

.ENDLOGICAL
