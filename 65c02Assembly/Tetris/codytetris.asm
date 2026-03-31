;
; codytetris.asm
; A Tetris Clone for the Cody Home Computer
;
;
; To assemble using 64TASS run the following:
;
;   64tass --mw65c02 --nostart -o codytetris.bin codytetris.asm
;
ADDR      = $0300               ; The actual loading address of the program

SCRRAM1   = $A000               ; Screen memory locations for double-buffering
SCRRAM2   = $A400

COLRAM1   = $A800               ; Color memory locations for double-buffering
COLRAM2   = $AC00

SPRITES   = $B000               ; Sprite memory locations

VIA_BASE  = $9F00               ; VIA base address and register locations
VIA_IORB  = VIA_BASE+$0
VIA_IORA  = VIA_BASE+$1
VIA_DDRB  = VIA_BASE+$2
VIA_DDRA  = VIA_BASE+$3
VIA_T1CL  = VIA_BASE+$4
VIA_T1CH  = VIA_BASE+$5
VIA_SR    = VIA_BASE+$A
VIA_ACR   = VIA_BASE+$B
VIA_PCR   = VIA_BASE+$C
VIA_IFR   = VIA_BASE+$D
VIA_IER   = VIA_BASE+$E

VID_BLNK  = $D000               ; Video blanking status register
VID_CNTL  = $D001               ; Video control register
VID_COLR  = $D002               ; Video color register
VID_BPTR  = $D003               ; Video base pointer register
VID_SCRL  = $D004               ; Video scroll register
VID_SCRC  = $D005               ; Video screen common colors register
VID_SPRC  = $D006               ; Video sprite control register

SPR0_X    = $D080               ; Sprite X coordinate
SPR0_Y    = $D081               ; Sprite Y coordinate
SPR0_COL  = $D082               ; Sprite color
SPR0_PTR  = $D083               ; Sprite base pointer

SID_BASE  = $D400               ; SID registers (mostly for voice 1)
SID_V1FL  = SID_BASE+0
SID_V1FH  = SID_BASE+1
SID_V1PL  = SID_BASE+2
SID_V1PH  = SID_BASE+3
SID_V1CT  = SID_BASE+4
SID_V1AD  = SID_BASE+5
SID_V1SR  = SID_BASE+6
SID_FVOL  = SID_BASE+24

MAP_WIDTH = 10
MAP_STRIDE = 40
MAP_HEIGHT = 20

TILE_EMPTY = 2
TILE_BLOCK = 3

PLAYFIELD_X_OFFSET = 10
PLAYFIELD_Y_OFFSET = 4


PLAYERX   = $D0
PLAYERY   = $D1
CURRENT_PIECE = $D2
CURRENT_ROT   = $D3

MAPPTR    = $D4       ; $D4,$D5
SCRPTR    = $D6       ; $D6,$D7
COLPTR    = $D8       ; $D8,$D9

BUFFLAG   = $DA
FWDREV    = $DB
TEMP      = $DC

TETPTR    = $DD       ; $DD,$DE
ROWMASK   = $DF

TABLEPTR  = $E0       ; $E0,$E1
TMPPTR    = $E2       ; $E2,$E3

LEFTOFFSET = $E4
RIGHTOFFSET = $E5
BOTTOMOFFSET = $E6
OLD_ROT = $E7
GRAVITY_COUNTER = $E8
GRAVITY_DELAY = $E9
FAST_DROP_DELAY = $EA
ROW_INDEX = $EB
SCORE = $EC
GAMEOVER_FLAG = $ED




; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program goes below here

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

;
; MAIN
;
; The starting point of the demo. Performs the necessary setup before the demo runs.
;
MAIN        LDA #10             ; leftmost visible playfield column
            STA PLAYERX
            LDA #3           ; first playfield row
            STA PLAYERY

            LDA #0
            STA CURRENT_PIECE
            LDA #1
            STA CURRENT_ROT

            STZ GRAVITY_COUNTER
            LDA #10
            STA GRAVITY_DELAY

            LDA #1
            STA FAST_DROP_DELAY

            STZ GAMEOVER_FLAG
            STZ SCORE

            STZ TETPTR
            STZ TETPTR+1

            STZ ROWMASK 
            STZ TEMP 
            STZ TABLEPTR
            STZ TABLEPTR+1

            STZ FWDREV          ; Player moving forward by default
            
            STZ BUFFLAG         ; Clear double buffer flag
            
            LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
            STA VIA_DDRA

            LDA #$06            ; Set VIA to read joystick 1
            STA VIA_IORA

            LDA #$01            ; Sprite bank 0, white as common color
            STA VID_SPRC
            
            LDA VID_COLR        ; Set border color to black
            AND #$F0
            STA VID_COLR

            LDA #$F0           ; Store shared colors (light grey and black)
            STA VID_SCRC
  
            LDA #$00            ; Standard Video Mode, no effects, no scrolling
            STA VID_CNTL

            LDX #0              ; Copy game map tiles into character memory
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #136
            BNE _COPYCHAR

            LDX #0              ; Copy sprite data into video memory
_COPYSPRT   LDA SPRITEDATA,X
            STA SPRITES,X
            INX
            CPX #255
            BNE _COPYSPRT
            
            LDA #$D8            ; Initial sprite color
            STA SPR0_COL

;
; LOOP
;
; Main loop of the CODYBROS demo. Control drops through here after setup
; and jumps back here at the end of every game loop.
;
LOOP        
            JSR DRAWTETRONOMINO
            BRA _DRAW
            
            
_DRAW       JSR DRAWSCRN        ; Draw the screen and sprite
            JSR DRAWSCORE
            JSR DELETETETRONOMINO

            
            LDA VIA_IORA        ; Read joystick
            LSR A
            LSR A
            LSR A
            
            BIT #16             ; Fire button?
            BEQ _FIRE
            
            BIT #8              ; Joystick right?
            BEQ _RIGHT
            
            BIT #4              ; Joystick left?
            BEQ _LEFT

            BIT #1
            BEQ _DoHardDrop

            
            JMP _NEXT

_DoHardDrop 
          JSR HARD_DROP 
          JMP _NEXT
            
_FIRE       JSR ROTATE_WITH_WALL_COLLISION                 ; Exit on fire button
            JMP _NEXT

_LEFT

        ; --- simulate move left ---
        DEC PLAYERX
        DEC PLAYERX

        JSR CAN_COLLIDE_WITH_BOARD
        CMP #1
        BEQ _UndoLeftMove   ; collision → undo

        JMP _NEXT          ; no collision → keep movement

_UndoLeftMove:
        INC PLAYERX
        INC PLAYERX
        JMP _NEXT
            
_RIGHT
        ; --- simulate move right ---
        INC PLAYERX
        INC PLAYERX

        JSR CAN_COLLIDE_WITH_BOARD
        CMP #1
        BEQ _UndoRightMove  ; collision → undo

        JMP _NEXT          ; no collision → keep movement

_UndoRightMove:
        DEC PLAYERX
        DEC PLAYERX
        JMP _NEXT

            
_NEXT     JSR GRAVITY_WRAPPER  
          JMP LOOP


;
; DRAWSCRN
;
; Draws the current visible of the screen. This routine uses double-buffering
; so that the new screen and colors are drawn to a different location, and the
; screens/colors are switched out during the vertical blanking interval.
;
; In a real application the screen may need to be drawn (offscreen) in sections
; to keep up with a high game frame rate. For an example this works well enough
; to avoid glitches or tearing during scrolling.
;
DRAWSCRN    LDA #<MAPDATA       ; Start map pointer at beginning of map
            STA MAPPTR+0
            LDA #>MAPDATA
            STA MAPPTR+1  
            
            LDA BUFFLAG         ; Determine what buffer to draw to
            TAX
            
            LDA SCRRAMS_L,X     ; Start screen pointer at beginning of buffer
            STA SCRPTR+0
            LDA SCRRAMS_H,X
            STA SCRPTR+1
            
            LDA COLRAMS_L,X     ; Start color pointer at beginning of buffer
            STA COLPTR+0
            LDA COLRAMS_H,X
            STA COLPTR+1
            
            LDX #25             ; For now, try drawing everything
            JSR COPYROWS
            
            JSR WAITBLANK       ; Wait for the blanking interval to make changes

            LDA BUFFLAG         ; Determine what buffer to flip to
            TAX
            
            LDA BASEREGS,X      ; Update base register for screen memory
            STA VID_BPTR
            
            LDA COLREGS,X       ; Update color register for color memory
            STA VID_COLR
            
            LDA BUFFLAG         ; Toggle buffer flag
            EOR #$01
            STA BUFFLAG

            
_DONE       RTS                 ; All done
            
;
; COPYROWS
;
; Copies a number of rows from the game map into the screen and color memory. The
; number of rows to copy is stored in the X register.
;  
COPYROWS    

_XLOOP      PHX
            LDY #0
            
_YLOOP      LDA (MAPPTR),Y      ; Copy the character (game tile) into screen memory 
            STA (SCRPTR),Y
            
            TAX                 ; Copy the color into color memory
            LDA COLORDATA,X
            STA (COLPTR),Y
            
            INY                 ; Next loop for Y
            CPY #40
            BNE _YLOOP
            
            CLC                 ; Increment map pointer to next row
            LDA MAPPTR+0
            ADC #40
            STA MAPPTR+0
            LDA MAPPTR+1
            ADC #0
            STA MAPPTR+1
            
            CLC                 ; Increment screen pointer to next row
            LDA SCRPTR+0
            ADC #40
            STA SCRPTR+0
            LDA SCRPTR+1
            ADC #0
            STA SCRPTR+1
            
            CLC                 ; Increment color pointer to next row
            LDA COLPTR+0
            ADC #40
            STA COLPTR+0
            LDA COLPTR+1
            ADC #0
            STA COLPTR+1
            
            PLX                 ; Next loop for X
            DEX
            BNE _XLOOP
            
            RTS                 ; All done




DRAWTETRONOMINO:

        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        LDY PLAYERY
AddRowLoop:
        CPY #0
        BEQ AddRowsDone
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        DEY
        BRA AddRowLoop
AddRowsDone:

        CLC
        LDA TMPPTR
        ADC PLAYERX
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        LDA CURRENT_PIECE
        ASL A
        ASL A               
        CLC
        ADC CURRENT_ROT     
        ASL A               
        TAX

        LDA TETROMINO_TABLE,X
        STA TETPTR
        INX
        LDA TETROMINO_TABLE,X
        STA TETPTR+1


        LDX #4                  
RowLoop:
        LDY #0                  

ColLoop:
        LDA (TETPTR),Y          
        BEQ SkipPixel

        LDA CURRENT_PIECE
        ASL 
        ADC #3
        STA (TMPPTR),Y
        INY
        LDA CURRENT_PIECE
        ASL
        ADC #4
        STA (TMPPTR),Y
        DEY

SkipPixel:
        INY
        INY                     
        CPY #8                 
        BNE ColLoop

        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        CLC
        LDA TETPTR
        ADC #8
        STA TETPTR
        LDA TETPTR+1
        ADC #0
        STA TETPTR+1

        DEX
        BNE RowLoop

        RTS


DELETETETRONOMINO:
        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        LDY PLAYERY
AddRowLoop2W:
        CPY #0
        BEQ AddRowsDone2W
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        DEY
        BRA AddRowLoop2W
AddRowsDone2W:

        CLC
        LDA TMPPTR
        ADC PLAYERX
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        LDA CURRENT_PIECE
        ASL A
        ASL A              
        CLC
        ADC CURRENT_ROT    
        ASL A              
        TAX

        LDA TETROMINO_TABLE,X
        STA TETPTR
        INX
        LDA TETROMINO_TABLE,X
        STA TETPTR+1


        LDX #4                  
RowLoop2W:
        LDY #0                  

ColLoop2W:
        LDA (TETPTR),Y         
        BEQ SkipPixel2W
        LDA #2
        STA (TMPPTR),Y
        INY
        STA (TMPPTR),Y
        DEY

SkipPixel2W:
        INY
        INY                     
        CPY #8                  
        BNE ColLoop2W

        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        CLC
        LDA TETPTR
        ADC #8
        STA TETPTR
        LDA TETPTR+1
        ADC #0
        STA TETPTR+1

        DEX
        BNE RowLoop2W

        RTS



LEFT_OFFSET:
        
        LDA CURRENT_PIECE
        ASL A
        ASL A               
        CLC
        ADC CURRENT_ROT     
        TAX                 

        LDA LEFT_OFFSET_TABLE,X
        STA LEFTOFFSET
        RTS



RIGHT_OFFSET:
        LDA CURRENT_PIECE
        ASL A
        ASL A               
        CLC
        ADC CURRENT_ROT     
        TAX                 

        LDA RIGHT_OFFSET_TABLE,X
        STA RIGHTOFFSET
        RTS


BOTTOM_OFFSET:
        LDA CURRENT_PIECE
        ASL A
        ASL A               
        CLC
        ADC CURRENT_ROT     
        TAX                 

        LDA BUTTOM_OFFSET_TABLE,X
        STA BOTTOMOFFSET
        RTS


ROTATE_WITH_WALL_COLLISION:
        LDA CURRENT_ROT
        STA OLD_ROT

        CLC
        ADC #1
        CMP #4
        BNE StoreNew
        LDA #0
StoreNew:
        STA CURRENT_ROT
        JSR CAN_COLLIDE_WITH_BOARD
        CMP #1
        BEQ RestoreRotation

        RTS

RestoreRotation:
        LDA OLD_ROT
        STA CURRENT_ROT
        RTS



GRAVITY:
        INC PLAYERY

        JSR CAN_COLLIDE_WITH_BOARD
        CMP #1
        BEQ StopFalling      ; collision lock piece

        RTS                  ; no collision keep falling

StopFalling:
        DEC PLAYERY          
        JSR DRAWTETRONOMINO
        JSR CHECK_ALL_ROWS_AND_DELETE_FULL
        JSR CHECK_GAMEOVER
        LDA GAMEOVER_FLAG
        CMP #1
        BEQ GAME_OVER_HANDLER
        INC CURRENT_PIECE
        LDA CURRENT_PIECE
        CMP #7
        BNE NoWrapPiece
        LDA #0
        STA CURRENT_PIECE
NoWrapPiece:
        STZ CURRENT_ROT
        LDA #10
        STA PLAYERX
        LDA #3
        STA PLAYERY
        RTS

GAME_OVER_HANDLER 
        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1
        
        LDA #71
        LDY #93
        STA (TMPPTR),Y
        LDA #65
        LDY #94
        STA (TMPPTR),Y
        LDA #77
        LDY #95
        STA (TMPPTR),Y
        LDA #69
        LDY #96
        STA (TMPPTR),Y
        LDA #79
        LDY #98
        STA (TMPPTR),Y
        LDA #86
        LDY #99
        STA (TMPPTR),Y
        LDA #69
        LDY #100
        STA (TMPPTR),Y
        LDA #82
        LDY #101
        STA (TMPPTR),Y

FILLMAP_FROM_OFFSET:

        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        CLC
        LDA TMPPTR
        ADC #120
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        LDX #22

FillRowLoop:
        PHX
        LDY #0

FillColLoop:
        LDA #2
        STA (TMPPTR),Y
        INY
        CPY #40
        BNE FillColLoop

        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        PLX
        DEX
        BNE FillRowLoop

        JSR DRAWSCRN

GAME_DONE JMP GAME_DONE


GRAVITY_WRAPPER:

        LDA VIA_IORA        ; Read joystick
        LSR A
        LSR A
        LSR A
        
        BIT #2
        BNE NormalGravity

        INC GRAVITY_COUNTER
        LDA GRAVITY_COUNTER
        CMP FAST_DROP_DELAY
        BCC NoFallYet
        STZ GRAVITY_COUNTER
        JSR GRAVITY
        RTS
NormalGravity:
        INC GRAVITY_COUNTER
        LDA GRAVITY_COUNTER
        CMP GRAVITY_DELAY
        BCC NoFallYet

        STZ GRAVITY_COUNTER
        JSR GRAVITY        
NoFallYet:
        RTS

HARD_DROP:
HardDropLoop:
        INC PLAYERY
        JSR CAN_COLLIDE_WITH_BOARD
        CMP #1
        BEQ HardDropStop
        BRA HardDropLoop

HardDropStop:
        DEC PLAYERY          

        
        JSR DRAWTETRONOMINO
        INC CURRENT_PIECE
        LDA CURRENT_PIECE
        CMP #7
        BNE NoWrapPiece2
        LDA #0
        STA CURRENT_PIECE
NoWrapPiece2:
        STZ CURRENT_ROT
        LDA #10
        STA PLAYERX
        LDA #3
        STA PLAYERY
        RTS


CAN_COLLIDE_WITH_BOARD:

        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        LDY PLAYERY
AddRowLoop_C:
        CPY #0
        BEQ AddRowsDone_C
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        DEY
        BRA AddRowLoop_C
AddRowsDone_C:

        CLC
        LDA TMPPTR
        ADC PLAYERX
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        LDA CURRENT_PIECE
        ASL A
        ASL A              
        CLC
        ADC CURRENT_ROT     
        ASL A               
        TAX

        LDA TETROMINO_TABLE,X
        STA TETPTR
        INX
        LDA TETROMINO_TABLE,X
        STA TETPTR+1
        LDX #4

RowLoop_C:
        LDY #0              

ColLoop_C:
        LDA (TETPTR),Y      
        BEQ SkipPixel_C

        LDA (TMPPTR),Y
        CMP #2
        BNE CollisionFound  ; anything not 2 -> collision

SkipPixel_C:
        INY
        INY                 
        CPY #8
        BNE ColLoop_C

        ; next map row
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1

        ; next tetromino row 
        CLC
        LDA TETPTR
        ADC #8
        STA TETPTR
        LDA TETPTR+1
        ADC #0
        STA TETPTR+1

        DEX
        BNE RowLoop_C

        ; no collision
        LDA #0
        RTS

CollisionFound:
        LDA #1
        RTS


CHECK_ALL_ROWS_AND_DELETE_FULL:
        LDX #22              
CheckLoop_All:
        STX ROW_INDEX       

        LDA ROW_INDEX
        JSR CHECK_ROW_FULL   

        CMP #1
        BNE NextRow_All

        JSR DELETE_ROW_AND_PULL_DOWN_FROM_ROW_INDEX

        JSR ADD_SCORE_1

       
        JMP CHECK_ALL_ROWS_AND_DELETE_FULL
        JMP CheckLoop_All

NextRow_All:
        DEX
        CPX #3
        BPL CheckLoop_All

        RTS


CHECK_ROW_FULL:
        STA ROW_INDEX

       
        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        LDY ROW_INDEX
RowPtrLoop:
        CPY #0
        BEQ RowPtrDone
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        DEY
        BRA RowPtrLoop

RowPtrDone:
        
        LDY #10
CheckLoop:
        LDA (TMPPTR),Y
        CMP #2
        BEQ NotFull           

        INY
        CPY #30
        BNE CheckLoop

       
        LDA #1
        
        RTS

NotFull:
        LDA #0
        RTS



DELETE_ROW_AND_PULL_DOWN_FROM_ROW_INDEX:

        
        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        LDY ROW_INDEX
DelRowPtrLoop:
        CPY #0
        BEQ DelRowPtrDone
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        DEY
        BRA DelRowPtrLoop

DelRowPtrDone:
       
        LDX ROW_INDEX        ; X = current row to fill

PullDownLoop:
        CPX #3               ; stop when we reach top playfield row (3)
        BEQ InsertEmptyTopRow

        
        LDY #10
CopyRow:
        SEC
        LDA TMPPTR
        SBC #40
        STA TMPPTR
        LDA TMPPTR+1
        SBC #0
        STA TMPPTR+1
        LDA (TMPPTR),Y      ; row above, same column
        PHA
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        PLA
        STA (TMPPTR),Y       ; into current row
        INY
        CPY #30
        BNE CopyRow

        ; Move TMPPTR up one row (to X-1)
        SEC
        LDA TMPPTR
        SBC #40
        STA TMPPTR
        LDA TMPPTR+1
        SBC #0
        STA TMPPTR+1

        DEX
        BRA PullDownLoop

InsertEmptyTopRow:
        LDY #10
FillEmpty:
        LDA #2               ; empty tile
        STA (TMPPTR),Y
        INY
        CPY #30
        BNE FillEmpty

        RTS

ADD_SCORE_1:
        SED         ; enable BCD mode
        CLC
        LDA SCORE
        ADC #1      ; add 1 in BCD
        STA SCORE
        CLD         ; disable BCD mode
        RTS

DRAWSCORE:
        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1
        LDA SCORE
        AND #$0F            ; low nibble 
        CLC
        ADC #48
        LDY #70
        STA (TMPPTR),Y

        LDA SCORE
        LSR A               ; shift high nibble down
        LSR A
        LSR A
        LSR A              
        CLC 
        ADC #48
        LDY #69
        STA (TMPPTR),Y

        RTS

CHECK_GAMEOVER:
        LDA #<MAPDATA
        STA TMPPTR
        LDA #>MAPDATA
        STA TMPPTR+1

        LDY #3
GoPtrLoop:
        CPY #0
        BEQ GoPtrDone
        CLC
        LDA TMPPTR
        ADC #40
        STA TMPPTR
        LDA TMPPTR+1
        ADC #0
        STA TMPPTR+1
        DEY
        BRA GoPtrLoop

GoPtrDone:

        LDY #10              
GoCheckLoop:
        LDA (TMPPTR),Y
        CMP #2
        BNE GameOverDetected ; any !2 tile -> game over

        INY
        CPY #30              
        BNE GoCheckLoop

        RTS                  

GameOverDetected:
        LDA #1
        STA GAMEOVER_FLAG
        RTS






;
; WAITBLANK
;
; Waits for the vertical blank signal to transition from drawing to not drawing, then
; returns. Used to sync up screen/register updates so they don't occur in the middle
; of the screen.
;
WAITBLANK

_WAITVIS    LDA VID_BLNK        ; Wait until the blanking is zero (drawing the screen)
            BNE _WAITVIS
            
_WAITBLANK  LDA VID_BLNK        ; Wait until the blanking is one (not drawing the screen)
            BEQ _WAITBLANK
            
            RTS

;
; The game map.
;
;0 = Grey Block A
;1 = Grey Block B
;2 = Blank 
;3 = Light Blue Block 
;4 = Light Blue Block 
;5 = Purple Block 
;6 = Purple Block 
;7 = Red Block 
;8 = Red Block 
;9 = Green Block 
;10 = Green Block 
;11 = Orange Block 
;12 = Orange Block 
;13 = Dark Blue Block 
;14 = Dark Blue Block 
;15 = Yellow Block 
;16 = Yellow Block 
;>=17 Letters
MAPDATA

  .BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,67,79,68,89,84,69,84,82,73,83,2,2,2,2,2,2,2,2,2,83,67,79,82,69,58,2,2,2,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,3,4,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,13,14,2,2,2,2
  .BYTE 2,2,3,4,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,13,14,13,14,2,2
  .BYTE 2,2,3,4,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,13,14,2,2
  .BYTE 2,2,3,4,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,11,12,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,11,12,2,2
  .BYTE 2,2,7,8,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,11,12,11,12,2,2
  .BYTE 2,2,7,8,7,8,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,7,8,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,9,10,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,9,10,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,9,10,9,10,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,15,16,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,15,16,15,16,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,5,6,5,6,2,2
  .BYTE 2,2,15,16,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,5,6,5,6,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,2,2,2,2,2,2,2,2
  .BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2

;
; The game's character tiles (used to draw the map).
;
CHARDATA

  .BYTE %11111111   ; Grey Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Grey Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111

  .BYTE %00000000   ; Blank
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %11111111   ; Light Blue Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Light Blue Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111



  .BYTE %11111111   ; Yellow Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Yellow Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111

  .BYTE %11111111   ; Purple Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Purple Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111


  .BYTE %11111111   ; Orange Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Orange Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111



  .BYTE %11111111   ; Dark Blue Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Dark Blue Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111


  .BYTE %11111111   ; Green Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Green Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111

  .BYTE %11111111   ; Red Block A
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11000000
  .BYTE %11111111

  .BYTE %11111111   ; Red Block B
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %00000011
  .BYTE %11111111



;
; The color date to copy for each tile type.
;
COLORDATA

  .BYTE   $0B       ; Grey Block (black and dark grey)
  .BYTE   $0B       ; Grey Block (black and dark grey)
  .BYTE   $00       ; Blank (black and black)
  .BYTE   $0E       ; Light Blue Block (black and light blue)
  .BYTE   $0E       ; Light Blue Block (black and light blue)
  .BYTE   $07       ; Yellow Block (black and yellow)
  .BYTE   $07       ; Yellow Block (black and yellow)
  .BYTE   $04       ; Purple Block (black and purple)
  .BYTE   $04       ; Purple Block (black and purple)
  .BYTE   $08       ; Orange Block (black and orange)
  .BYTE   $08       ; Orange Block (black and orange)
  .BYTE   $06       ; Dark Blue Block (black and dark blue)
  .BYTE   $06       ; Dark Blue Block (black and dark blue)
  .BYTE   $05       ; Green Block (black and green)
  .BYTE   $05       ; Green Block (black and green)
  .BYTE   $02       ; Red Block (black and red)
  .BYTE   $02       ; Red Block (black and red)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
  .BYTE   $50       ; text (black and green)
; The sprite data for the Pomeranian sprite on the screen.
;


;bitmasks for tetronominos



TET_O_0:
    .byte 1,1,1,1,0,0,0,0
    .byte 1,1,1,1,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_O_1 = TET_O_0
TET_O_2 = TET_O_0
TET_O_3 = TET_O_0

TET_I_0:
    .byte 1,1,1,1,1,1,1,1
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_I_1:
    .byte 0,0,1,1,0,0,0,0
    .byte 0,0,1,1,0,0,0,0
    .byte 0,0,1,1,0,0,0,0
    .byte 0,0,1,1,0,0,0,0

TET_I_2 = TET_I_0
TET_I_3 = TET_I_1

TET_T_0:
    .byte 0,0,1,1,1,1,1,1   
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_T_1:
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,0,0,0,0,0,0

TET_T_2:
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,1,1,1,1,1,1   
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_T_3:
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,0,0,0,0,0,0

TET_L_0:
    .byte 0,0,1,1,1,1,1,1   
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_L_1:
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,0,0,0,0,0,0

TET_L_2:
    .byte 0,0,0,0,0,0,1,1  
    .byte 0,0,1,1,1,1,1,1   
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_L_3:
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,0,0,0,0,0,0


TET_J_0:
    .byte 0,0,1,1,1,1,1,1   
    .byte 0,0,0,0,0,0,1,1  
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_J_1:
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,0,0,0,0,0,0

TET_J_2:
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,1,1,1,1,1,1  
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_J_3:
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,1,1,0,0,0,0  
    .byte 0,0,0,0,0,0,0,0

TET_S_0:
    .byte 0,0,0,0,1,1,1,1   
    .byte 0,0,1,1,1,1,0,0  
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_S_1:
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,0,0,0,0,0,0

TET_S_2 = TET_S_0
TET_S_3 = TET_S_1

TET_Z_0:
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,0,0,1,1,1,1   
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

TET_Z_1:
    .byte 0,0,0,0,1,1,0,0   
    .byte 0,0,1,1,1,1,0,0   
    .byte 0,0,1,1,0,0,0,0   
    .byte 0,0,0,0,0,0,0,0

TET_Z_2 = TET_Z_0
TET_Z_3 = TET_Z_1

TETROMINO_TABLE:
    .word TET_I_0, TET_I_1, TET_I_2, TET_I_3
    .word TET_O_0, TET_O_1, TET_O_2, TET_O_3
    .word TET_T_0, TET_T_1, TET_T_2, TET_T_3
    .word TET_L_0, TET_L_1, TET_L_2, TET_L_3
    .word TET_J_0, TET_J_1, TET_J_2, TET_J_3
    .word TET_S_0, TET_S_1, TET_S_2, TET_S_3
    .word TET_Z_0, TET_Z_1, TET_Z_2, TET_Z_3


LEFT_OFFSET_TABLE:



    ; I piece
    .byte 0   ; I0  horizontal  
    .byte 1   ; I1  vertical    
    .byte 0   ; I2  same as I0
    .byte 1   ; I3  same as I1


    ; O piece (always left-aligned)
    .byte 0   ; O0
    .byte 0   ; O1
    .byte 0   ; O2
    .byte 0   ; O3


    ; T piece
    .byte 1   ; T0  
    .byte 1   ; T1  
    .byte 1   ; T2  
    .byte 1   ; T3  

    ; L piece
    .byte 1   ; L0  
    .byte 1   ; L1  
    .byte 1   ; L2  
    .byte 1   ; L3  

    ; J piece
    .byte 1   ; J0  
    .byte 1   ; J1  
    .byte 1   ; J2  
    .byte 1   ; J3  

    ; S piece
    .byte 1   ; S0  
    .byte 1   ; S1  
    .byte 1   ; S2  
    .byte 1   ; S3  

    ; Z piece
    .byte 1   ; Z0  
    .byte 1   ; Z1  
    .byte 1   ; Z2  
    .byte 1   ; Z3  

RIGHT_OFFSET_TABLE:
    ; I piece
    .byte 0   ; I0  
    .byte 2   ; I1  
    .byte 0   ; I2
    .byte 2   ; I3

    ; O piece (always 2 blocks wide)
    .byte 2   ; O0
    .byte 2   ; O1
    .byte 2   ; O2
    .byte 2   ; O3

    ; T piece
    .byte 0   ; T0  
    .byte 1   ; T1  
    .byte 0   ; T2  
    .byte 1   ; T3  

    ; L piece
    .byte 0   ; L0  
    .byte 1   ; L1  
    .byte 0   ; L2  
    .byte 1   ; L3  

    ; J piece
    .byte 0   ; J0  
    .byte 1   ; J1  
    .byte 0   ; J2  
    .byte 1   ; J3  

    ; S piece
    .byte 0   ; S0  
    .byte 1   ; S1  
    .byte 0   ; S2
    .byte 1   ; S3

    ; Z piece
    .byte 0   ; Z0  
    .byte 1   ; Z1  
    .byte 0   ; Z2
    .byte 1   ; Z3

BUTTOM_OFFSET_TABLE:

    ; I piece
    .byte 3   
    .byte 0   
    .byte 3   
    .byte 0   

    ; O piece (always left-aligned)
    .byte 2   
    .byte 2   
    .byte 2   
    .byte 2   


    ; T piece
    .byte 2   
    .byte 1   
    .byte 2   
    .byte 1   

    ; L piece
    .byte 2   
    .byte 1   
    .byte 2   
    .byte 1   

    ; J piece
    .byte 2   
    .byte 1   
    .byte 2   
    .byte 1   

    ; S piece
    .byte 2   
    .byte 1   
    .byte 2   
    .byte 1   

    ; Z piece
    .byte 2   
    .byte 1   
    .byte 2   
    .byte 1   

SPRITEDATA

  .BYTE %00000000,%00000001,%01000000   ; Pomeranian forward 0
  .BYTE %00010000,%00001101,%11110000
  .BYTE %00010000,%00001101,%01111111
  .BYTE %01010100,%00000101,%01010000
  .BYTE %01010100,%00110101,%01110000
  .BYTE %01010100,%10110101,%01010101
  .BYTE %01010100,%10111001,%01010111
  .BYTE %01010111,%10101110,%01010100
  .BYTE %01010111,%10101110,%01010000
  .BYTE %01010111,%10101110,%10100000
  .BYTE %00010110,%11101110,%10100000
  .BYTE %00011010,%11101110,%10100000
  .BYTE %00001010,%11101110,%10000000
  .BYTE %00001010,%10111010,%10000000
  .BYTE %00010110,%10111001,%01010000
  .BYTE %00010101,%01000001,%01010000
  .BYTE %01010101,%00000000,%01010000
  .BYTE %01010000,%00000000,%01010000
  .BYTE %01010000,%00000000,%01010000
  .BYTE %00010100,%00000000,%00010100
  .BYTE %00010100,%00000000,%00010100
  .BYTE %00000000

  .BYTE %00000000,%00000001,%01000000 ; Pomeranian forward 1
  .BYTE %00010000,%00001101,%11110000
  .BYTE %00010000,%00001101,%01111111
  .BYTE %01010100,%00000101,%01010000
  .BYTE %01010100,%00110101,%01110000
  .BYTE %01010100,%10110101,%01010101
  .BYTE %01010100,%10111001,%01010111
  .BYTE %01010111,%10101110,%01010100
  .BYTE %01010111,%10101110,%01010000
  .BYTE %01010111,%10101110,%10100000
  .BYTE %00010110,%11101110,%10100000
  .BYTE %00011010,%11101110,%10100000
  .BYTE %00001010,%11101110,%10000000
  .BYTE %00001010,%10111010,%10000000
  .BYTE %00000110,%10111001,%01000000
  .BYTE %00010101,%01000001,%01000000
  .BYTE %00010101,%00000101,%00000000
  .BYTE %00000101,%00000101,%00000000
  .BYTE %00010101,%00000101,%00000000
  .BYTE %01010100,%00000001,%01000000
  .BYTE %01010000,%00000001,%01000000
  .BYTE %00000000

  .BYTE %00000001,%01000000,%00000000   ; Pomeranian reverse 0
  .BYTE %00001111,%01110000,%00000100
  .BYTE %11111101,%01110000,%00000100
  .BYTE %00000101,%01010000,%00010101
  .BYTE %00001101,%01011100,%00010101
  .BYTE %01010101,%01011110,%00010101
  .BYTE %11010101,%01101110,%00010101
  .BYTE %00010101,%10111010,%11010101
  .BYTE %00000101,%10111010,%11010101
  .BYTE %00001010,%10111010,%11010101
  .BYTE %00001010,%10111011,%10010100
  .BYTE %00001010,%10111011,%10100100
  .BYTE %00000010,%10111011,%10100000
  .BYTE %00000010,%10101110,%10100000
  .BYTE %00000101,%01101110,%10010100
  .BYTE %00000101,%01000001,%01010100
  .BYTE %00000101,%00000000,%01010101
  .BYTE %00000101,%00000000,%00000101
  .BYTE %00000101,%00000000,%00000101
  .BYTE %00010100,%00000000,%00010100
  .BYTE %00010100,%00000000,%00010100
  .BYTE %00000000

  .BYTE %00000001,%01000000,%00000000   ; Pomeranian reverse 1
  .BYTE %00001111,%01110000,%00000100
  .BYTE %11111101,%01110000,%00000100
  .BYTE %00000101,%01010000,%00010101
  .BYTE %00001101,%01011100,%00010101
  .BYTE %01010101,%01011110,%00010101
  .BYTE %11010101,%01101110,%00010101
  .BYTE %00010101,%10111010,%11010101
  .BYTE %00000101,%10111010,%11010101
  .BYTE %00001010,%10111010,%11010101
  .BYTE %00001010,%10111011,%10010100
  .BYTE %00001010,%10111011,%10100100
  .BYTE %00000010,%10111011,%10100000
  .BYTE %00000010,%10101110,%10100000
  .BYTE %00000001,%01101110,%10010000
  .BYTE %00000001,%01000001,%01010100
  .BYTE %00000000,%01010000,%01010100
  .BYTE %00000000,%01010000,%01010000
  .BYTE %00000000,%01010000,%01010100
  .BYTE %00000001,%01000000,%00010101
  .BYTE %00000001,%01000000,%00000101
  .BYTE %00000000

;
; Lookup tables for screen and color memory locations. Used to quickly
; switch between the double buffer during an update.
;
SCRRAMS_L

  .BYTE <SCRRAM1
  .BYTE <SCRRAM2
  
SCRRAMS_H

  .BYTE >SCRRAM1
  .BYTE >SCRRAM2

COLRAMS_L

  .BYTE <COLRAM1
  .BYTE <COLRAM2
  
COLRAMS_H

  .BYTE >COLRAM1
  .BYTE >COLRAM2

BASEREGS

  .BYTE $05
  .BYTE $15

COLREGS

  .BYTE $20
  .BYTE $30
  
LAST                              ; End of the entire program

.ENDLOGICAL
