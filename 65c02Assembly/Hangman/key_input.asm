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
