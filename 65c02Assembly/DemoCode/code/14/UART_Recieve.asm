; Recieves bytes via UART and print them on the screen
; 64tass --mw65c02 --nostart -o UART_Recieve.bin UART_Recieve.asm
; plink -batch -serial \\.\COMX -sercfg "19200,8,1,n,N" < input.bin
; Author: Lukas Lang

.include "codyconstants.asm"

UART_BASE = $D480               ; UART Memory start, ($D480 = UART 1(PROP PLUG)) 
                                ; $D4A0 = UART 2 (expansion port))
UART_COMMAND = UART_BASE + 1    ; Command Register, 0 = off, 1 = on
UART_STATUS = UART_BASE + 2     ; Status Register
UART_HEAD = UART_BASE + 4       ; Recieve Ringbuffer Head
UART_TAIL = UART_BASE + 5       ; Recieve Ringbuffer Tail
BUFFER_POINTER = UART_BASE + 8  ; Start of recieve Ringbuffer
BAUD_RATE = $F                  ; F = 19200

SCREEN_POINTER = $C400          ; assumes screen memory is set to start at $C400
COLOR_POINTER = $D800           ; assumes color memory is set to start at $D800

;Variables for various UART regs
ERROR = $D0                     
HEAD = $D3                      
TAIL = $D5                      

LAST_BYTE = $D7                      ; last byte recieved
BYTE_COUNTER = $D9              ; How many bytes recieved

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
            STZ LAST_BYTE
            STZ BYTE_COUNTER
            
            LDA CHARDATA        ; only character is empty character (TODO)
            STA $C800
            LDA #$00
            JSR CLEAR_SCREEN    ; replace all characters with empty character

            ; UART TIME

            LDA #$00            ; turn off uart
            STA UART_COMMAND

            JSR WAIT_UNTIL_DOWN

            LDA #BAUD_RATE      ; set baud rate, set in first UART reg
            STA UART_BASE     

            LDA #$00            ; reset recieve ring buffer tail
            STA UART_TAIL     

            LDA #$01            ; turn on uart
            STA UART_COMMAND

            JSR WAIT_UNTIL_READY

_RECIEVE_LOOP
            LDA UART_STATUS     ; read status and check for errors
            STA ERROR 
            JSR ERROR_CHECK 

            LDA UART_HEAD       ; read recieve head and tail
            STA HEAD
            LDA UART_TAIL
            STA TAIL

            LDA HEAD            ; if head == tail nothing recieved, keep checking
            CMP TAIL
            BEQ _RECIEVE_LOOP    

            LDX TAIL            ; read from recieve ringbuffer + tail
            LDA BUFFER_POINTER,X
            STA LAST_BYTE 

            LDA TAIL            ; adjust tail
            INC A
            AND #%00000111      ; MOD 8, ringbuffer only holds 8 bytes
            STA UART_TAIL       

            LDX BYTE_COUNTER    ; print recieved byte, byte counter used as offset into screen
            LDA LAST_BYTE 
            STA SCREEN_POINTER,X
            LDA #$50            ; set text to green, background black
            STA COLOR_POINTER,X

            CLC                 ; BYTE_COUNTER++
            LDA BYTE_COUNTER
            ADC #$01
            STA BYTE_COUNTER

            JMP _RECIEVE_LOOP


; check for errors, exit program on error
ERROR_CHECK                     
            LDA ERROR 
            AND #$02            ; bit 1 = framing error
            BNE _DONE
            
            LDA ERROR 
            AND #$04            ; bit 2 = overrun
            BNE _DONE 
            RTS

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

.include "graphics.asm"

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

