
; assumes: 
; SCREEN MEM at $C400 
; COLOR MEM at $D800
; first tile is "empty tile"
CLEAR_SCREEN
; set characters from $C400 to $C500 to empty tile
            LDX #0              
_EMPTY0
            STZ $C400,X
            STZ $D800,X ;0=black
            INX
            BNE _EMPTY0
; set characters from $C500 to $C600 to empty tile
            LDX #0              
_EMPTY1
            STZ $C500,X
            STZ $D900,X ;0=black
            INX
            BNE _EMPTY1

; set characters from $C600 to $C700 to empty tile
            LDX #0              
_EMPTY2
            STZ $C600,X
            STZ $DA00,X ;0=black
            INX
            BNE _EMPTY2
; set characters from $C700 to $C800 to empty tile
            LDX #0              
_EMPTY3
            STZ $C700,X
            STZ $DB00,X ;0=black
            INX
            BNE _EMPTY3
    RTS