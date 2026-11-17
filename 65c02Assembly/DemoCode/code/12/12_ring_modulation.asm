; ported to assembly from Cody Book Page 384 
; 64tass --mw65c02 --nostart -o 12_ring_modulation.bin 12_ring_modulation.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < 12_ring_modulation.bin

.include "codyconstants.asm"

FRAMECTR = $D4

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here   

            LDX #$00            ; clear all registers (sounds and settings)
    _CLEAR
            STZ SID_BASE, X
            INX
            CPX #$28
            BNE _CLEAR

            LDA #14             ; set volume to ~ max
            STA SID_FVOL

            LDA #$00            ; set frequency to 10240 (622 Hz = D5# tone)
            STA SID_V1FL        
            LDA #$28
            STA SID_V1FH

            LDA #$A0            ; attack = A (68 ms), decay = 0 (750 ms)
            STA SID_V1AD
            
            LDA #$FB            ; sustain = 15, release = 11 (3 s)
            STA SID_V1SR

            LDA #$00            ; set frequency to 2560 (155 Hz = D3# tone)
            STA SID_V3FL
            LDA #$0A
            STA SID_V3FH

            LDA #$15            ; bit4=triangle wave, bit2=ring modulation on, bit0=start sound
            STA SID_V1CT

            STZ FRAMECTR        ; FRAMECTR=0  

    _LOOP       

            JSR WAITBLANK       ; Wait for the next frame

            LDA FRAMECTR        ; FRAMECTR++
            INC A
            STA FRAMECTR

            CMP #$78            ; turn of after 120 frames (2 seconds)
            BNE _CONTINUE
            LDA #$14            ; turn of (bit0=0)
            STA SID_V1CT
            RTS                 ; return to CODY BASIC

    _CONTINUE    

            JMP _LOOP           ; Game loops          

.include "graphics.asm"

LAST                            ; End of the entire program

.ENDLOGICAL
