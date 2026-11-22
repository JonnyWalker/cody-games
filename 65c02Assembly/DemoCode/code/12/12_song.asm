; ported to assembly from Cody Book Page 369 (Tom Dooley)
; 64tass --mw65c02 --nostart -o 12_song.bin 12_song.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < 12_song.bin

.include "codyconstants.asm"

TONE_LEN   = $D5
TONE_PAUSE = $D6
TONE_PTR   = $D7

TONE_NUMBER = #$19
PAUSE_TIME  = #$01

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here   
            JSR SOUND_INIT
    _LOOP    
            JSR WAITBLANK       ; Wait for the next frame
            JSR PLAY_SOUND      ; play sound
            JMP _LOOP


; Subroutine to be used before calling PLAY_SOUND
SOUND_INIT
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

            STZ TONE_LEN        ; TONE_LEN = 0
            STZ TONE_PAUSE      ; TONE_PAUSE = 0
            STZ TONE_PTR        ; TONE_PTR = 0
            RTS


; Subroutine which plays sound
; 
; TONE_LEN: length of the tone
; TONE_PAUSE: pause time between notes
; TONE_PTR: points to next tone
; FREQUENCY_HI and FREQUENCY_LO: frequency of current tone
; TONE_LENGTH: length of current tone
PLAY_SOUND
            LDA TONE_PAUSE      ; Wait pause time if TONE_PAUSE != 0
            BNE _TONE_PAUSE

    _SOUND_IS_PLAYING
            LDA TONE_LEN        ; only play new tone when tone time is over
            BEQ _NEW_TONE_SETUP

            DEC TONE_LEN        ; TONE_LEN--    
            RTS

    _NEW_TONE_SETUP
            LDX TONE_PTR
            CPX TONE_NUMBER     ; all TONE_NUMBER tones played?
            BNE _NO_SONG_RESET
            STZ TONE_PTR        ; loop song
    _NO_SONG_RESET 

            LDX TONE_PTR        ; X = TONE_PTR

            LDA TONE_LENGTH, X  ; get length of next tone
            STA TONE_LEN

            LDA FREQUENCY_LO, X ; get frquency of next tone
            STA SID_V1FL        
            LDA FREQUENCY_HI, X
            STA SID_V1FH 

            INC TONE_PTR        ; TONE_PTR++ (point to next tone)

            LDA PAUSE_TIME      ; TONE_PAUSE=PAUSE_TIME
            STA TONE_PAUSE

            LDA #$40            ; bit6=pulse wave, bit0=start sound (tone disbaled)
            STA SID_V1CT        ; disable voice for TONE_PAUSE time
            RTS

    _TONE_PAUSE                 ; enable sound if TONE_PAUSE-- == 0
            DEC TONE_PAUSE
            BEQ _ENABLE_SOUND_AFTER_PAUSE   
            RTS 

    _ENABLE_SOUND_AFTER_PAUSE
            LDA #$41            ; bit6=pulse wave, bit0=start sound (tone enable)
            STA SID_V1CT
            RTS    

.include "graphics.asm"


; C4$, C4$, C4$, D4$, F4$
; A4$, A4$, C4$, C4$, C4$
; D4$, F4$, G4$, C4$, C4$
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

; Page 360: adjust time 250->16 frames, 500->32 frames,
; 1000->64 frames
TONE_LENGTH 
.BYTE 16, 32, 16, 32, 32
.BYTE 64, 64, 16, 32, 16
.BYTE 32, 32, 128, 16, 32
.BYTE 16, 32, 32, 64, 64
.BYTE 32, 16, 32, 32, 96

LAST                            ; End of the entire program

.ENDLOGICAL
