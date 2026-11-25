; combined scrolling
; BASIC to Assembly port form Book page 323-327
; Check for Q Key not ported 

.include "codyconstants.asm"

FRAME_CTR     = $D0   ; (variable S in Book)
BUFFER_FLAG   = $D1   ; (variable B2 in Book)
SCREEN_MEM_PTR0 = $D2 ; (variable A(0)+I in Book)
SCREEN_MEM_PTR1 = $D4 ; (variable A(1)+I in Book)

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E6            ; Set border color (Bits 0-3) to blue=6 
                                ; and set color memory to $D800 (A000+14*1024=D800), E=14
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
            LDA #$05            ; Set character memory to $C800 (A000+5*2048=C800)
                                ; and set screen memory location $A000 (A000+0*1024=A000)
            STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)

            ; fill both 1KB of screen memory
            STZ SCREEN_MEM_PTR0+0
            LDA #$A4
            STA SCREEN_MEM_PTR0+1

            STZ SCREEN_MEM_PTR1+0
            LDA #$A0
            STA SCREEN_MEM_PTR1+1

            ; create pattern (with offset) in both screen memorys (and buffer)
            LDX #$04
    _OUTER_LOOP
            LDY #$00 
    _INNER_LOOP
            TYA
            AND #$01
            BEQ _EVEN
    _ODD    
            LDA #$C2                 ; CODSCII: checkered square
            STA (SCREEN_MEM_PTR0), Y
            LDA #$20                 ; CODSCII: white space
            STA (SCREEN_MEM_PTR1), Y
            JMP _NEXT
    _EVEN   
            LDA #$20                 ; CODSCII: white space
            STA (SCREEN_MEM_PTR0), Y
            LDA #$C2                 ; CODSCII: checkered square
            STA (SCREEN_MEM_PTR1), Y
    _NEXT

            INY
            CPY #250
            BNE _INNER_LOOP

            CLC                      ; Increment pointer by 250 (tiles)
            LDA SCREEN_MEM_PTR0+0
            ADC #250
            STA SCREEN_MEM_PTR0+0
            LDA SCREEN_MEM_PTR0+1
            ADC #0
            STA SCREEN_MEM_PTR0+1

            CLC                      ; Increment pointer by 250 (tiles)
            LDA SCREEN_MEM_PTR1+0
            ADC #250
            STA SCREEN_MEM_PTR1+0
            LDA SCREEN_MEM_PTR1+1
            ADC #0
            STA SCREEN_MEM_PTR1+1

            DEX
            BNE _OUTER_LOOP

            ; FRAME_CTR = 0
            STZ FRAME_CTR

            ; set start scroll value to 0 pixels
            LDA #$00
            STA VID_SCRL

            ; enable scrolling mode
            LDA VID_CNTL
            ORA #$04
            STA VID_CNTL

    LOOP   
            ; flip BUFFER_FLAG every four frames 
            ; by checking if BIT-2 is set
            ; FRAME_CTR runs from 0 to 7
            LDA FRAME_CTR
            LSR
            LSR
            AND #$01
            BEQ _BUFFER1
    _BUFFER0
            LDA #$05
            STA BUFFER_FLAG
            JMP _WAIT
    _BUFFER1
            LDA #$15
            STA BUFFER_FLAG
    _WAIT
            ; wait for blank before scroll (and optional buffer switch)
    _WAITBLANK
            ; Wait until the blanking is one (not drawing the screen)
            LDA VID_BLNK
            BEQ _WAITBLANK
            
            ; scroll horizontal by FRAME_CTR mod 4 pixels
            ; Bit 4-7 of VID_SCRL is used for 
            ; horizontal scroll (so multiply by 16 by shifting)
            LDA FRAME_CTR
            ORA #$03
            ASL 
            ASL 
            ASL
            ASL 
            STA VID_SCRL

            ; flip buffer (other character memory location) every four frames
            ; by writing BUFFER_FLAG
            LDA BUFFER_FLAG
            STA VID_BPTR

            ; FRAME_CTR ++
            INC FRAME_CTR

            ; if FRAME_CTR == 8 then FRAME_CTR = 0
            ; this implements FRAME_CTR = (FRAME_CTR+1) mod 8
            LDA FRAME_CTR
            CMP #$08
            BNE _SKIP_FRAME_CTR_RESET
            LDA #$00
            STA FRAME_CTR
    _SKIP_FRAME_CTR_RESET

    _WAITVIS
            ; Wait until the blanking is zero (drawing the screen)
            LDA VID_BLNK
            BNE _WAITVIS

            JMP LOOP

LAST        ; End of the entire program

.ENDLOGICAL
