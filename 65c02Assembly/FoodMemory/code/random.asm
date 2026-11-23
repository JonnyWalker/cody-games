; MARK: SUB INIT_RANDOM
; init voice 3 rng
INIT_RANDOM
    ; switch voice 3 to noise mode with maximum frequency to generate random values in SID_V3OC ($D41B)
    LDA #$FF
    STA SID_V3FL
    STA SID_V3FH
    LDA #$80
    STA SID_V3CT
    RTS


; MARK: SUB GET_RANDOM_BYTE_TO_A
; read noise from SID until we see a new value
GET_RANDOM_BYTE_TO_A
    LDA SID_V3OC
    CMP LAST_RANDOM_VALUE
    BEQ GET_RANDOM_BYTE_TO_A
    STA LAST_RANDOM_VALUE
    RTS


; MARK: SUB COMPUTE_RANDOM_TILE_SET
; randomly select one of
; 4 available tile sets
COMPUTE_RANDOM_TILE_SET
    JSR GET_RANDOM_BYTE_TO_A
    AND #3
    ASL
    TAX
    LDA MEMORY_SETS_PIXELS,X
    LDY MEMORY_SETS_COLORS,X
    STA CHAR_ROM_PTR16 + 0
    STY COLOR_ROM_PTR + 0
    INX
    LDA MEMORY_SETS_PIXELS,X
    LDY MEMORY_SETS_COLORS,X
    STA CHAR_ROM_PTR16 + 1
    STY COLOR_ROM_PTR + 1
    RTS

; MARK: SUB COMPUTE_RANDOM_LEVEL
COMPUTE_RANDOM_LEVEL               
    ; idea: for all cards,
    ; draw random index

    LDX #23
_zero
    STZ LEVEL,X
    DEX
    BPL _zero
                                ;
    LDY #25                     ; 24 iterations.
                                ; we start at 25 so that Y / 2
                                ; produces card values 12...1,
                                ; each exactly twice. if we
                                ; started at 24 we would produce one 0.
_loop                           ;
    JSR GET_RANDOM_BYTE_TO_A    ; get random byte, and convert to
    TAX                         ; index into level. mod 24 using
    LDA MOD_24,X                ; a lookup table.
    TAX                         ;
    LDA LEVEL,X                 ; check if card at that index is 0.
    BNE _loop                   ; if its not, then theres already a
                                ; card assigned; try again.
    TYA                         ;
    LSR                         ; div 2 to map 25...1 to 12...1
    STA LEVEL,X                 ; store card id at chosen index.
    DEY                         ;
    CPY #1                      ;
    BNE _loop                   ;
    RTS
