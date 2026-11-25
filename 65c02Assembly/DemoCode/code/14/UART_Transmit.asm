; Transmit bytes (keyboard key pressed) via UART
; 64tass --mw65c02 --nostart -o UART_Transmit.bin UART_Transmit.asm
; Author: Lukas Lang

.include "codyconstants.asm"

UART_BASE = $D480               ; UART Memory start, ($D480 = UART 1(PROP PLUG)) 
                                ; $D4A0 = UART 2 (expansion port))
UART_COMMAND = UART_BASE + 1    ; Command Register, 0 = off, 1 = on
UART_STATUS = UART_BASE + 2     ; Status Register
UART_HEAD = UART_BASE + 6       ; Transmit Ringbuffer Head
UART_TAIL = UART_BASE + 7       ; Transmit Ringbuffer Tail
BUFFER_POINTER = UART_BASE + 16 ; Start of transmit Ringbuffer
BAUD_RATE = $F                  ; F = 19200

;Variables for various UART regs
ERROR = $D0                     
HEAD = $D3                      
TAIL = $D5                      

NEXT_BYTE = $D7                      ; byte to sent

; Program header for Cody Basic's loader (needs to be first)

.WORD ADDR                      ; Starting address (just like KIM-1, Commodore, etc.)
.WORD (ADDR + LAST - MAIN - 1)  ; Ending address (so we know when we're done loading)

; The actual program.

.LOGICAL    ADDR                ; The actual program gets loaded at ADDR

MAIN                            ; The program starts running from here
            LDA #$E2            ; Set border color (Bits 0-3) to red=2 
                                ; and set color memory to $D800 (A000+14*1024=D800), E=14
            STA VID_COLR        ; VID_COLR=$D002 (see codyconstants.asm)
            LDA #$95            ; Set character memory to $C800 (A000+5*2048=C800)
                                ; and set screen memory location $C400 (A000+9*1024=C400)
            STA VID_BPTR        ; VID_BPTR=$D003 (see codyconstants.asm)

            LDA #$E2            ; Store shared colors (light blue=14 and red=2)
            STA VID_SCRC        ; VID_SCRC=$D005 (see codyconstants.asm) 

            STZ ERROR           ; Zero Variables
            STZ HEAD
            STZ TAIL 
            STZ NEXT_BYTE
            
            LDA CHARDATA        ; only character is empty character
            STA $C800
            LDA #$00
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            ; UART TIME

            LDA #$00            ; turn off uart
            STA UART_COMMAND

            JSR WAIT_UNTIL_DOWN

            LDA #BAUD_RATE      ; set baud rate, set in first UART reg
            STA UART_BASE     

            LDA #$00            ; reset transmit ring buffer head
            STA UART_HEAD     

            LDA #$01            ; turn on uart
            STA UART_COMMAND

            JSR WAIT_UNTIL_READY

_TRANSMIT_LOOP
            LDA UART_HEAD       ; read transmit head and tail
            STA HEAD
            LDA UART_TAIL
            STA TAIL

            LDA HEAD            ; loop until at least 1 byte is free in buffer
                                ; (loop while abs(H-T)>6 meaning buffer is full)
            CMP TAIL 
            BCC _HEAD_L_TAIL
            SEC                 ; head>tail so we do head-tail-7
            SBC TAIL 
            SEC 
            SBC #$07
            BCS _TRANSMIT_LOOP
            JMP _SENT_NEXT_BYTE
_HEAD_L_TAIL                    ; tail>head so we do tail-head-7
            LDA TAIL 
            SEC
            SBC HEAD 
            SEC
            SBC #$07
            BCS _TRANSMIT_LOOP

_SENT_NEXT_BYTE
            JSR KEY_TO_A
            LDX HEAD            ; write to recieve ringbuffer + head
            STA BUFFER_POINTER,X

            LDA HEAD            ; adjust head
            INC A
            AND #%00000111      ; MOD 8, ringbuffer only holds 8 bytes
            STA UART_HEAD 

            JMP _TRANSMIT_LOOP

_DONE       JMP _DONE           ; Loops forever

; poll status register and  
; loop until UART status reg is updated
WAIT_UNTIL_DOWN
_WAIT
            LDA UART_STATUS   
            AND #$40
            BNE _WAIT
            RTS

; poll status register and  
; loop until UART status reg is updated
WAIT_UNTIL_READY
_WAIT
            LDA UART_STATUS   
            AND #$40
            BEQ _WAIT
            RTS

.include "key_input.asm"        ; get key pressed

.include "graphics.asm"         ; make screen black

CHARDATA

  .BYTE %00000000   ; "empty tile"
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000
  .BYTE %00000000

LAST                            ; End of the entire program

.ENDLOGICAL

