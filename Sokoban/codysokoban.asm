;
; codysokoban.asm
; TODO: write some description
;
; Copyright 2025 John Witulski
;
;
; To assemble using 64TASS run the following:
;
;   64tass --mw65c02 --nostart -o codysokoban.bin codysokoban.asm
; To run in the emulator:
;

.include "codyconstants.asm"

MAP_WIDTH = #40                 ; never bigger than 255
PLAYERX   = $D0                 ; Player coordinates
PLAYERY   = $D1
NEXT_X    = $D2                 ; Pos the Player wants to move to
NEXT_Y    = $D3  

MAPPTR    = $D4                 ; Memory pointers for drawing the screen
SCRPTR    = $D6
COLPTR    = $D8

BUFFLAG   = $DA                 ; Flag indicating what buffer is being used
FWDREV    = $DB                 ; Flag indicating player direction (forward or reverse)

TEMP      = $DC                 ; Temporary variable
RET_VAL   = $DD                 ; 2 bytes
ARG       = $DF                 ; used to pass arguments 


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
MAIN        LDA #100
            STA PLAYERX         ; Reset player position
            STA NEXT_X
            LDA #80
            STA PLAYERY
            STA NEXT_Y

            STZ FWDREV          ; Player moving forward by default
            
            STZ BUFFLAG         ; Clear double buffer flag
            
            LDA #$07            ; Set VIA data direction register A to 00000111 (pins 0-2 outputs, pins 3-7 inputs)     
            STA VIA_DDRA

            LDA #$06            ; Set VIA to read joystick 1
            STA VIA_IORA

            LDA #$00            ; Sprite bank 0, black as common color
            STA VID_SPRC
            
            LDA VID_COLR        ; Set border color to black
            AND #$F0
            STA VID_COLR

            LDA #$90            ; Store shared colors (brown and black)
            STA VID_SCRC
  
            STZ VID_CNTL        ; Disable all features (e.g. scrolling)

            LDX #0              ; Copy game map tiles into character memory
_COPYCHAR   LDA CHARDATA,X
            STA $C800,X
            INX
            CPX #80
            BNE _COPYCHAR

            LDX #0              ; Copy sprite data into video memory
_COPYSPRT   LDA SPRITEDATA,X
            STA SPRITES,X
            INX
            CPX #255
            BNE _COPYSPRT
            
            LDA #$6A            ; Initial sprite color (light red and blue)
            STA SPR0_COL

;
; LOOP
;
; Main loop of the CODYBROS demo. Control drops through here after setup
; and jumps back here at the end of every game loop.
;
LOOP        JSR DRAWSCRN        ; Draw the screen and sprite
            JSR DRAWSPRT
            
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

            BIT #2              ; Joystick down to swap colors?
            BEQ _DOWN
            
            BIT #1              ; Joystick up to bark?
            BEQ _UP
            
            BRA LOOP
            
_FIRE       RTS                 ; Exit on fire button

_LEFT       LDA #1              ; Move left
            STA FWDREV
            
            LDA PLAYERX
            CLC
            SBC #1
            STA NEXT_X

            BRA _NEXT
            
_RIGHT      STZ FWDREV          ; Move right
            
            LDA PLAYERX
            ADC #1
            STA NEXT_X

            BRA _NEXT

_DOWN       STZ FWDREV          ; TODO use variabel UPDOWN, use FWDREV for now

            LDA PLAYERY
            ADC #1
            STA NEXT_Y

            BRA _NEXT

_UP         LDA #1              ; TODO use variabel UPDOWN, use FWDREV for now
            STA FWDREV

            LDA PLAYERY
            CLC
            SBC #1
            STA NEXT_Y

            BRA _NEXT

_NEXT
            LDA NEXT_X          ; Pass arguments
            STA ARG+0
            LDA NEXT_Y
            STA ARG+1
            LDA #<MAPDATA       ; Start map pointer at beginning of map
            STA ARG+2
            LDA #>MAPDATA
            STA ARG+3
            LDA MAP_WIDTH
            STA ARG+4
            LDA #0              ; last tile value with no collsion
            STA ARG+5
            JSR COMPUTE_COLISSION

            LDA RET_VAL         ; Read current tile in Tile Map
            CMP #1
            BEQ _COLISSION

            LDA NEXT_X          ; Pass arguments
            ADC #12
            STA ARG+0
            LDA NEXT_Y
            STA ARG+1
            LDA #<MAPDATA       ; Start map pointer at beginning of map
            STA ARG+2
            LDA #>MAPDATA
            STA ARG+3
            LDA MAP_WIDTH
            STA ARG+4
            LDA #0              ; last tile value with no collsion
            STA ARG+5
            JSR COMPUTE_COLISSION

            LDA RET_VAL         ; Read current tile in Tile Map
            CMP #1
            BEQ _COLISSION    

            LDA NEXT_X          ; Pass arguments
            STA ARG+0
            LDA NEXT_Y
            ADC #21
            STA ARG+1
            LDA #<MAPDATA       ; Start map pointer at beginning of map
            STA ARG+2
            LDA #>MAPDATA
            STA ARG+3
            LDA MAP_WIDTH
            STA ARG+4
            LDA #0              ; last tile value with no collsion
            STA ARG+5
            JSR COMPUTE_COLISSION

            LDA RET_VAL         ; Read current tile in Tile Map
            CMP #1
            BEQ _COLISSION    

            LDA NEXT_X          ; Pass arguments
            ADC #12
            STA ARG+0
            LDA NEXT_Y
            ADC #21
            STA ARG+1
            LDA #<MAPDATA       ; Start map pointer at beginning of map
            STA ARG+2
            LDA #>MAPDATA
            STA ARG+3
            LDA MAP_WIDTH
            STA ARG+4
            LDA #0              ; last tile value with no collsion
            STA ARG+5
            JSR COMPUTE_COLISSION

            LDA RET_VAL         ; Read current tile in Tile Map
            CMP #1
            BEQ _COLISSION    

            BRA _CONTINUE
_COLISSION
            LDA PLAYERX         ; Dont change pos and exit 
            STA NEXT_X
            LDA PLAYERY
            STA NEXT_Y

            JMP LOOP            
_CONTINUE
            LDA NEXT_X          ; Use changes and exit
            STA PLAYERX
            LDA NEXT_Y
            STA PLAYERY

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
            
            RTS                 ; All done

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
            ADC MAP_WIDTH
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

;
; DRAWSPRT
;
; Draws the sprite in the correct location for this frame. Note that the sprite
; isn't "drawn" so much as its registers updated so that it appears correctly.
; This should be called after drawing the screen because we want to sneak in 
; during the vertical blank.
;
DRAWSPRT    LDA PLAYERX         ; Calculate new sprite location
            STA SPR0_X
            
            LDA PLAYERY         ; Update sprite Y
            STA SPR0_Y
            
            LDA FWDREV          ; Update sprite base pointer (different frames)
            ASL A
            STA TEMP
            CLC
            LDA PLAYERX
            AND #$02
            LSR A
            ADC TEMP
            ADC #(4096/64)
            STA SPR0_PTR
            
            RTS


.include "codyengine.asm"




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


; The game map.
;
; 0 = nothing
; 1 = Brick
; 2 = ?
; 3 = ?
; 4 = ?
; 5 = ?
; 6 = ?
; 7 = ?
; 8 = ?
; 9 = ?
;
MAPDATA

  .BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
  .BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

;
; The game's character tiles (used to draw the map).
;
CHARDATA

  .BYTE %11111111   ; Sky
  .BYTE %11111111
  .BYTE %11111111
  .BYTE %11111111
  .BYTE %11111111
  .BYTE %11111111
  .BYTE %11111111
  .BYTE %11111111

  .BYTE %01010101   ; Brick
  .BYTE %01000000
  .BYTE %01000000
  .BYTE %01000000
  .BYTE %01010101
  .BYTE %00000001
  .BYTE %00000001
  .BYTE %00000001

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

  .BYTE %00000000   ; Unused
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

;
; The color date to copy for each tile type.
;
COLORDATA

  .BYTE   $09       ; Sky (black and brown)
  .BYTE   $02       ; Brick (black and red)
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused
  .BYTE   $00       ; Unused

;
; The sprite data for the Pomeranian sprite on the screen.
;
SPRITEDATA

  .BYTE %00000000,%11111100,%00000000  ; Player right 0
  .BYTE %00010000,%11010101,%01000000 
  .BYTE %00001100,%00010100,%00000100
  .BYTE %00000011,%00111100,%00110000
  .BYTE %00000000,%11111111,%11000000
  .BYTE %00000000,%00101000,%00000000
  .BYTE %00000000,%00101000,%00000000
  .BYTE %00000000,%10101000,%00000000
  .BYTE %00000010,%10001010,%00000000
  .BYTE %00001010,%00000010,%10000000
  .BYTE %00111000,%00000000,%10100000
  .BYTE %00110000,%00000000,%00111100
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000

  .BYTE %00000000,%11111100,%00000000  ; Player right 1
  .BYTE %00000000,%11010101,%00000000 
  .BYTE %00000000,%00010100,%00000000
  .BYTE %00000000,%00111100,%11110100
  .BYTE %00000000,%11111111,%00000000
  .BYTE %00000011,%00101000,%00000000
  .BYTE %00001100,%00101000,%00000000
  .BYTE %00010000,%10101000,%00000000
  .BYTE %00000000,%10001010,%00000000
  .BYTE %00000010,%10000010,%00110000
  .BYTE %00000010,%00000000,%10110000
  .BYTE %00000011,%11000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000

  .BYTE %00000000,%00111111,%00000000  ; Player left 0
  .BYTE %00000000,%01010111,%00000100 
  .BYTE %00010000,%00010100,%00110000 
  .BYTE %00001100,%00111100,%11000000
  .BYTE %00000011,%11111111,%00000000
  .BYTE %00000000,%00101000,%00000000
  .BYTE %00000000,%00101000,%00000000
  .BYTE %00000000,%00101010,%00000000
  .BYTE %00000010,%10000010,%10000000
  .BYTE %00001010,%00000000,%10100000
  .BYTE %00001000,%00000000,%00101100
  .BYTE %00111100,%00000000,%00001100
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000

  .BYTE %00000000,%00111111,%00000000  ; Player left 1
  .BYTE %00000000,%01010111,%00000000 
  .BYTE %00000000,%00010100,%00000000  
  .BYTE %00011111,%00111100,%00000000 
  .BYTE %00000000,%11111111,%00000000 
  .BYTE %00000000,%00101000,%11000000 
  .BYTE %00000000,%00101000,%00110000 
  .BYTE %00000000,%00101010,%00000100 
  .BYTE %00000000,%10100010,%00000000 
  .BYTE %00001100,%10000010,%10000000 
  .BYTE %00001110,%00000000,%10000000
  .BYTE %00000000,%00000011,%11000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
  .BYTE %00000000,%00000000,%00000000
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
