.include "codyconstants.asm"

; Zero Page

CURSOR_X = $D0          ; location of the next Letter to be printed 
KEY_PRESSED = $D1       ; codscii value of the pressed key
WRONG_LETTERS = $D2     ; inc every time the letters is not part of the word
SECRET_WORD_START = $D3
SECRET_WORD_LEN = $D4
RANDOM_VALUE = $D5      ; TODO: used to select a random word

; CONSTANTS where to print
WORD_PRINT_START = $C478
LETTER_PRINT_START = $C4AA
MESSAGE_PRINT_START = $C4C8
BLANK_CHAR = $00
MAX_MISTAKES = #$05

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


_TITLE_SCREEN
            LDA #$2C            ; clear with red=2 and gray=C 
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            LDX #0
    _Print_Text4
            LDA Text4, X
            STA $C428, X  
            INX
            CPX #7
            BNE _Print_Text4

            LDX #0
    _Print_Text5
            LDA Text5, X
            STA $C450, X  
            INX
            CPX #31
            BNE _Print_Text5

 _NEXT_GAME ; game loop jumps back here after game end
            LDX #0
    _Print_Text6
            LDA Text6, X
            STA $C798, X  
            INX
            CPX #24
            BNE _Print_Text6

    _WAIT_FOR_SPACE
        ; random between 0 and 255
        LDA RANDOM_VALUE
        INC A
        STA RANDOM_VALUE

        ; check for space key
        JSR KEY_TO_A
        CMP #$20
        BNE _WAIT_FOR_SPACE 

_NEW_GAME
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

            ; print number of letters
            ; TODO(BUG): only works for word length <10
            CLC
            ADC #48  ; '0' char starts at codscii value 48
            STA $C432

_GAME_LOOP
        ; TODO: wait blank and draw hangman       
        JSR KEY_TO_A
        BEQ _GAME_LOOP
        CMP #$20
        BEQ _GAME_LOOP ; SPACE
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
        ; new letter

        ; print key/letter (codscii value) at LETTER_PRINT_START+X
        LDX CURSOR_X
        LDA KEY_PRESSED
        STA LETTER_PRINT_START, X

        ; CURSOR_X++
        TXA
        INC A
        STA CURSOR_X

        ; Check if letter in word by iterating over the secret word
        LDY #$00 ; Y=false, letter not in word
        LDX #$00
 _CHECK_IF_IN_WORD
        LDA KEY_PRESSED
        CMP Words, X
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
        LDY #$00 ; Y = false = not won
 _NO_BLANK
        INX 
        CPX SECRET_WORD_LEN
        BNE _CHECK_WON

        ; skip won message if false
        CPY #$00
        BEQ _NOT_WON

        ; print won text
        LDX #0
 _Print_Won_Text
        LDA Text2, X
        STA MESSAGE_PRINT_START, X  
        INX
        CPX #8
        BNE _Print_Won_Text
        JMP _NEXT_GAME

 _NOT_WON        
        JMP _GAME_LOOP
        
 _LETTER_NOT_IN_WORD
        ; new letter and not in word
        LDA WRONG_LETTERS
        INC A
        STA WRONG_LETTERS

        ; check game over state
        CMP MAX_MISTAKES
        BNE _NOT_GAME_OVER

        ; print game over text
        LDX #0
 _Print_Gameover_Text
        LDA Text3, X
        STA MESSAGE_PRINT_START, X  
        INX
        CPX #9
        BNE _Print_Gameover_Text
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

LAST                            ; End of the entire program

.ENDLOGICAL
