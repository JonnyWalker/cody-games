; combined scrolling
; BASIC to Assembly port form Book page 323-327

.include "codyconstants.asm"


FRAME_CTR     = $D0   ; (variable S in Book)
BUFFER_FLAG   = $D1   ; (variable B2 in Book)
CHAR_MEM_PTR0 = $D2   ; (variable A(0)+I in Book)
CHAR_MEM_PTR1 = $D4   ; (variable A(1)+I in Book)


; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E2            ; Set border color (Bits 0-3) to red=2 
                                ; and set color memory to $D800 (A000+14*1024=D800), E=14
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
            LDA #$05            ; Set character memory to $A000 (A000+0*2048=A000)
                                ; and set screen memory location $C400 (A000+9*1024=C400)
            STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)

            LDA #$E2            ; Store shared colors  
                                ; Color 3: light blue=14, Color 2: red=2
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm)

            ; fill 2x character memory
            STZ CHAR_MEM_PTR0+0
            LDA #$A4
            STA CHAR_MEM_PTR0+1

            STZ CHAR_MEM_PTR1+0
            LDA #$A0
            STA CHAR_MEM_PTR1+1

            ; create pattern (with offset) in both character memorys (and buffer)
            LDX #$04
    _OUTER_LOOP
            LDY #$00 
    _INNER_LOOP
            TYA
            AND #$01
            BEQ _EVEN
    _ODD    
            LDA #$C2 
            STA (CHAR_MEM_PTR0), Y
            LDA #$14
            STA (CHAR_MEM_PTR1), Y
            JMP _NEXT
    _EVEN   
            LDA #$14 
            STA (CHAR_MEM_PTR0), Y
            LDA #$C2
            STA (CHAR_MEM_PTR1), Y
    _NEXT

            INY
            CPY #250
            BNE _INNER_LOOP

            CLC                 ; Increment pointer by 250
            LDA CHAR_MEM_PTR0+0
            ADC #250
            STA CHAR_MEM_PTR0+0
            LDA CHAR_MEM_PTR0+1
            ADC #0
            STA CHAR_MEM_PTR0+1

            CLC                 ; Increment pointer by 250
            LDA CHAR_MEM_PTR1+0
            ADC #250
            STA CHAR_MEM_PTR1+0
            LDA CHAR_MEM_PTR1+1
            ADC #0
            STA CHAR_MEM_PTR1+1

            DEX
            BNE _OUTER_LOOP

            ; FRAME_CTR = 0
            STZ FRAME_CTR

            ; start scroll by 0 pixels
            LDA #$00
            STA VID_SCRL

            ; enable scrolling
            LDA VID_CNTL
            ORA #$04
            STA VID_CNTL

    LOOP   
            ; flip BUFFER_FLAG every four frames
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
            JSR WAITBLANK
            
            ; scroll horizontal by FRAME_CTR mod 4 pixels
            ; Bit 4-7 of VID_SCRL is used for horizontal scroll (so multiply by 16 by shifting)
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

            JSR WAITBLANK

            JMP LOOP

.include "graphics.asm"

LAST                ; End of the entire program

.ENDLOGICAL
