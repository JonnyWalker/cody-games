; MARK: SUB MODULO_XP1
; calculate A = A % (X+1)
MODULO_XP1
    STX _DIVISOR
    INC _DIVISOR
_sub_loop
    CMP _DIVISOR
    BCC _done    ; branch if A < _DIVISOR
    SEC
    SBC _DIVISOR
    JMP _sub_loop
_done
    RTS

_DIVISOR
    .BYTE 0
