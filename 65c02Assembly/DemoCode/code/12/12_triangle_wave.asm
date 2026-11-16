; ported to assembly from Cody Book Page 361 (triangle waves)
; 64tass --mw65c02 --nostart -o 12_triangle_waves.bin 12_triangle_waves.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < 12_triangle_waves.bin

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

            LDA #15             ; set volume to max
            STA SID_FVOL

            LDA #$C4            ; set frequency to 5828 (340 Hz = F4 tone)
            STA SID_V1FL        
            LDA #$16
            STA SID_V1FH

            LDA #$69            ; attack = 6 (68 ms), decay = 9 (750 ms)
            STA SID_V1AD
            
            LDA #$FC            ; sustain = 15, release = 12 (3 s)
            STA SID_V1SR

            LDA #$11            ; bit4=triangle wave, bit0=start sound
            STA SID_V1CT

            STZ FRAMECTR        ; FRAMECTR=0  

    _LOOP       

            JSR WAITBLANK       ; Wait for the next frame

            LDA FRAMECTR        ; FRAMECTR++
            INC A
            STA FRAMECTR

            CMP #$78            ; turn of after 120 frames (2 seconds)
            BNE _CONTINUE
            LDA #$10            ; turn of (bit0=0)
            STA SID_V1CT
            RTS                 ; return to CODY BASIC

    _CONTINUE    

            JMP _LOOP           ; Game loops          

.include "graphics.asm"

LAST                            ; End of the entire program

.ENDLOGICAL
