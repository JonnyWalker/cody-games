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


; MARK: SUB GET_RANDOM_BYTE_TO_A_WITH_MAX
; get random value in 0..=MAX, where MAX is passed in X
GET_RANDOM_BYTE_TO_A_WITH_MAX
    ; check: if MAX = 0 the random number is always 0
    CPX #0          ; IF MAX != 0...
    BNE _next_check ; ...GOTO _next_check
    LDA #0
    RTS             ; ELSE return 0

_next_check
    ; check: if MAX = 255 we can directly return the random value without any calculations
    CPX #255      ; IF MAX != 255...
    BNE _slow_path  ; ...GOTO _slow_path
    JMP GET_RANDOM_BYTE_TO_A ; ELSE return byte directly from GET_RANDOM_BYTE_TO_A (note: JSR/RTS not required because GET_RANDOM_BYTE_TO_A is already a subroutine)

_slow_path
    ; slow path:
    ; we generate random numbers until we get one in the range 0..=LIMIT, where 0 <= LIMIT <= 255
    ; LIMIT is chosen, so that there is no bias when calculating the remainder of the random number with MAX+1
    ; this is the case when LIMIT+1 % MAX+1 = 0, or LIMIT = (n * (MAX+1)) - 1 for n>=1
    ; the biggest LIMIT that fulfills that property is LIMIT = 255 - (256 % (MAX+1))
    ; then we return the random number % MAX+1

    ; we have to calculate 256 % (MAX+1)
    ; first calculate A = 255 % (MAX+1), now we have A < MAX+1 <= 255
    LDA #255
    JSR MODULO_XP1
    ; then increment...
    INA
    ; ...and set to zero if A = MAX+1 -> A >= MAX+1 -> A > MAX
    STX _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT    ; cannot directly compare with MAX in X, so we use _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT as temp var
    CMP _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT
    BEQ _mod_not_done                           ; if A > MAX set A = 0
    BCS _mod_done
_mod_not_done
    LDA #0
_mod_done
    STA _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT    ; use _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT as temp var to save the result of 256 % (MAX+1)
    
    LDA #255
    SEC
    SBC _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT
    STA _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT    ; store final LIMIT in _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT

_rand_loop
    JSR GET_RANDOM_BYTE_TO_A
    CMP _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT
    ; continue _rand_loop if A > _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT
    BEQ _done         ; break if A = _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT
    BCS _rand_loop    ; continue if A >= _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT, but the case A = _GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT was already handled
_done
    JMP MODULO_XP1    ; JSR/RTS not required, use direct JMP

_GET_RANDOM_BYTE_TO_A_WITH_MAX_LIMIT
    .BYTE 0


; MARK: SUB COMPUTE_RANDOM_TILE_SET
; randomly select one of
; 4 available tile sets
COMPUTE_RANDOM_TILE_SET
    LDX #3
    JSR GET_RANDOM_BYTE_TO_A_WITH_MAX
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
    ; fill the LEVEL array with 1,1,2,2,3,3,...,12,12
    ; LEVEL,X = (X+2) / 2
    LDX #23
_fill_loop
    TXA
    CLC
    ADC #2
    LSR
    STA LEVEL,X
    DEX
    BPL _fill_loop ; can use BPL (checks highest bit) because the start value is less than 128

    ; shuffle the LEVEL array according to https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    ; this works by "collecting" the shuffled elements on the right and in each iteration randomly selecting one element to add - similar to selection sort
    ; start with the current position i at the end of the array (i=n-1)
    ; then until the current position is 1:
    ; randomly select one index 0 <= j <= i and swap it with the element at position i and decrement i
    LDX #23
_swap_loop
    JSR GET_RANDOM_BYTE_TO_A_WITH_MAX
    TAY

    ; swap LEVEL,X and LEVEL,Y using the XOR swap algorithm: https://en.wikipedia.org/wiki/XOR_swap_algorithm
    LDA LEVEL,X
    CMP LEVEL,Y    ; skip the swap if the values are identical
    BEQ _skip_swap ; the XOR swap algorithm only requires that the memory locations are different (X!=Y), but that is hard to check

    ; A contains LEVEL,X
    EOR LEVEL,Y
    STA LEVEL,X
    ; A and LEVEL,X contain LEVEL,X xor LEVEL,Y
    EOR LEVEL,Y
    STA LEVEL,Y
    ; A and LEVEL,Y contain LEVEL,X
    LDA LEVEL,X
    ; A again contains LEVEL,X xor LEVEL,Y
    EOR LEVEL,Y ; LEVEL,Y was already set to the previous LEVEL,X
    STA LEVEL,X
    ; A and LEVEL,X contain LEVEL,Y

_skip_swap
    DEX
    BNE _swap_loop ; last iteration has X=1, we skip X=0

    RTS
