
; assumes: 
; SCREEN MEM at $C400 
; COLOR MEM at $D800
; tile 0 is "empty tile"
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

; ROM location $E000: CODSCII characters are always there. 
; assumes CHAR MEM at $C800
LOAD_CODSCII_TO_CHAR_MEM
        LDX #0        
_COPYCHAR0  
        LDA $E000,X   
        STA $C000,X
        INX
        BEQ _COPYCHAR0 ; use overflow    
_COPYCHAR1 
        LDA $E100,X   
        STA $C100,X
        INX
        BEQ _COPYCHAR1 ; use overflow
_COPYCHAR2 
        LDA $E200,X   
        STA $C200,X
        INX
        BEQ _COPYCHAR2 ; use overflow
_COPYCHAR3 
        LDA $E300,X   
        STA $C300,X
        INX
        BEQ _COPYCHAR3 ; use overflow
_COPYCHAR4 
        LDA $E400,X   
        STA $C400,X
        INX
        BEQ _COPYCHAR4 ; use overflow
_COPYCHAR5 
        LDA $E500,X   
        STA $C500,X
        INX
        BEQ _COPYCHAR5 ; use overflow
_COPYCHAR6 
        LDA $E600,X   
        STA $C600,X
        INX
        BEQ _COPYCHAR6 ; use overflow
_COPYCHAR7 
        LDA $E700,X   
        STA $C700,X
        INX
        BEQ _COPYCHAR7 ; use overflow
        RTS
