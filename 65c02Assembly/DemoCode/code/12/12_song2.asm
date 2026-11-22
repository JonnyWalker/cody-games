; ported to assembly from Cody Book Page 369 (Tom Dooley)
; 64tass --mw65c02 --nostart -o 12_song.bin 12_song.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < 12_song.bin

.include "codyconstants.asm"

TONE_LEN   = $D5
TONE_PAUSE = $D6
TONE_PTR   = $D7

TONE_NUMBER = #$1A
PAUSE_TIME  = #$01

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here   

            LDX #$00            ; clear all registers (sounds and settings)
            JSR SOUND_INIT
    _LOOP    
            JSR WAITBLANK       ; Wait for the next frame
            JSR PLAY_SOUND      ; play sound
            JMP _LOOP


; Subroutine to be used before calling PLAY_SOUND
SOUND_INIT
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


C4 = $1125
D4 = $133F
E4 = $159A
F4 = $16E3
G4 = $1981
A4 = $1CD6
B4 = $202E
FREQUENCY_HI 
.Byte >(C4), >(C4), >(C4), >(D4), >(F4)
.BYTE >(A4), >(A4)
.BYTE >(C4), >(C4), >(C4), >(D4), >(F4)
.BYTE >(G4)

.Byte >(C4), >(C4), >(C4), >(D4), >(F4)
.BYTE >(G4), >(G4)
.BYTE >(G4), >(G4), >(A4), >(F4), >(D4)
.BYTE >(F4)

FREQUENCY_LO 
.BYTE <(C4), <(C4), <(C4), <(D4), <(F4)
.BYTE <(A4), <(A4)
.BYTE <(C4), <(C4), <(C4), <(D4), <(F4)
.BYTE <(G4)

.Byte <(C4), <(C4), <(C4), <(D4), <(F4)
.BYTE <(G4), <(G4)
.BYTE <(G4), <(G4), <(A4), <(F4), <(D4)
.BYTE <(F4)

; eighth->16 frames, quarter->32 frames, half->64 frames
TONE_LENGTH 
.BYTE 16, 32, 16, 32, 32
.BYTE 16, 48              ; 32+16
.BYTE 16, 32, 16, 32, 32
.BYTE 96                  ; 64+32

.BYTE 16, 32, 16, 32, 32
.BYTE 16, 48              ; 32+16
.BYTE 16, 32, 16, 32, 32
.BYTE 96                  ; 64+32


LAST                            ; End of the entire program

.ENDLOGICAL
