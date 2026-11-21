; ported to assembly from Cody Book Page 369 (Tom Dooley)
; 64tass --mw65c02 --nostart -o 12_song.bin 12_song.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < 12_song.bin

.include "codyconstants.asm"

FRAMECTR = $D4
TONE_LEN = $D5

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

            LDA #$FF            ; duty cycle ~6% (255/4096)
            STA SID_V1PL
            LDA #$00
            STA SID_V1PH

            LDA #$09            ; attack = 0 (2 ms), decay = 9 (750 ms)
            STA SID_V1AD
            
            LDA #$00            ; sustain = 0, release = 0 (6 ms)
            STA SID_V1SR

            STZ FRAMECTR        ; FRAMECTR = 0
            STZ TONE_LEN        ; TONE_LEN = 0
            LDX #$00            ; X=0 (tone counter)

    _LOOP    
            LDA TONE_LEN        ; play new tone when time is over
            BNE _SKIP_NEW_TONE

            ; wait 3 frames between tones 
            STZ FRAMECTR        ; FRAMECTR = 0  

            LDA #$40            ; bit6=pulse wave, bit0=stop sound
            STA SID_V1CT          
     _WAIT
            JSR WAITBLANK       ; Wait for the next frame

            LDA FRAMECTR        ; FRAMECTR++
            INC A
            STA FRAMECTR

            CMP #03             ; FRAMECTR == 3 ?
            BNE _WAIT

            LDA TUNE_LENGTH, X  ; get length of next tune
            STA TONE_LEN

            LDA FREQUENCY_LO, X ; get frquency of next tune
            STA SID_V1FL        
            LDA FREQUENCY_HI, X
            STA SID_V1FH 

            LDA #$41            ; bit6=pulse wave, bit0=start sound
            STA SID_V1CT

            INX                 ; X++ (point to next tone)

    _SKIP_NEW_TONE
            
            LDA TONE_LEN        ; TONE_LEN--
            DEC A
            STA TONE_LEN

            JSR WAITBLANK       ; Wait for the next frame

            CPX #$19            ; all 25 tones played?
            BNE _CONTINUE
            RTS                 ; return to CODY BASIC

    _CONTINUE    

            JMP _LOOP           ; Game loops          

.include "graphics.asm"


; C4$, C4$, C4$, D4$, F4$
; A4$, A4$, C4$, C4$, C4$
; D4$, F4$, G4$, C4$, C4$,
; C4$, D4$, F4$, G4$, G4$
; G4$, A4 , F4$, D4$, F4$
FREQUENCY_HI 
.Byte $12, $12, $12, $14, $18
.BYTE $1E, $1E, $12, $12, $12
.BYTE $14, $18, $1B, $12, $12 
.BYTE $12, $14, $18, $1B, $1B
.BYTE $1B, $1E, $18, $14, $18

FREQUENCY_LO 
.BYTE $68, $68, $68, $A9, $92
.BYTE $F5, $F5, $68, $68, $68
.BYTE $A9, $92, $94, $68, $68
.BYTE $68, $A9, $92, $94, $94
.BYTE $94, $F5, $92, $A9, $92

; Page 360: adjust time 250->15 frames, 500->30 frames, 1000->60 frames
TUNE_LENGTH 
.BYTE 15, 30, 15, 30, 30
.BYTE 60, 60, 15, 30, 15
.BYTE 30, 30, 120, 15, 30
.BYTE 15, 30, 30, 60, 60
.BYTE 30, 15, 30, 30, 90

LAST                            ; End of the entire program

.ENDLOGICAL
