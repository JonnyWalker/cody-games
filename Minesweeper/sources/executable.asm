SIZE            = LAST - 1 - MAIN
ADDR            = $9EFF-SIZE            ; Program header for Cody BASIC's loader (needs to be first)
.WORD ADDR                              ; Starting address (just like KIM-1, Commodore, etc.)
.WORD LAST - 1                          ; Ending address (so we know when we're done loading)
.LOGICAL        ADDR                    ; The actual program gets loaded at ADDR

.cpu            "65c02"





LOAD_IMM        .macro imm, reg
                .if (<(\imm)) != 0
                LDA #<(\imm)
                STA \reg
                .else
                STZ \reg
                .endif

                .if (>(\imm)) != 0
                LDA #>(\imm)
                STA \reg + 1
                .else
                STZ \reg + 1
                .endif
                .endmacro

BRUH            = $C0

VIA_BASE        = $9F00
VIA_IORB        = VIA_BASE+$0
VIA_IORA        = VIA_BASE+$1
VIA_DDRB        = VIA_BASE+$2
VIA_DDRA        = VIA_BASE+$3
VIA_T1CL        = VIA_BASE+$4
VIA_T1CH        = VIA_BASE+$5
VIA_SR          = VIA_BASE+$A
VIA_ACR         = VIA_BASE+$B
VIA_PCR         = VIA_BASE+$C
VIA_IFR         = VIA_BASE+$D
VIA_IER         = VIA_BASE+$E

VID_CTRL_REG    = $D001
VID_CTRL_CLR    = $D002
VID_CTRL_PXL    = $D003
VID_CTRL_SHC    = $D005
VID_VRAM_PXL    = $A000
VID_VRAM_CLR    = $D800
                




TILE_PIXEL      = $F0
TILE_COLOR      = $F2

BASEADDR        = $D0


M1              = $B0


MAIN            JSR INITIALIZATION

                LDA #<$A000
                STA baseaddr
                LDA #>$A000
                STA baseaddr + 1

                LDY #11
_draw_everything
                TYA
                BIT #1
                BEQ _skip

                LDA #0

                BRA _skip2
_skip           
                LDA #2
_skip2


                LDX #11
_draw_row_loop  
                PHA
                JSR OLD_DRAW_TILE
                #load_imm 16, M1
                JSR addition
                PLA 
                DEX
                BPL _draw_row_loop


                #load_imm 448, M1
                JSR addition

                DEY
                BPL _draw_everything



.INCLUDE        "initialization.asm"

_done           BRA _done
                LDX #$FD                ; resetting the 
                TXS                     ; hardware SP to FD
                JMP ($FFFC)             ; Jump to Reset Vector






                ; final_address = $A000 + x*8 + y*8*40











PARAM_0              = $A0
PARAM_1              = $A1
PARAM_3              = $A3
PARAM_4              = $A4
PARAM_5              = $A5
PARAM_6              = $A6
PARAM_7              = $A7
PARAM_8              = $A8
PARAM_9              = $A9
PARAM_A              = $AA
PARAM_B              = $AB
PARAM_C              = $AC
PARAM_D              = $AD
PARAM_E              = $AE
PARAM_F              = $AF


;; PARAM_0: index of the tile to draw
;; PARAM_1: X coordinate of the tile on the game board
;; PARAM_2: Y coordinate of the tile on the game board
DRAW_TILE       










;; calling convention:
;; A Register: Index of the Tile to draw
;; X: X
;; Y: Y
OLD_DRAW_TILE   PHY

                TAY
                LDA TILE_COLOR_TABLE,Y

               

                

                ASL
                TAY
                LDA TILE_SPRITE_TABLE,Y
                STA tile_pixel
                INY
                LDA TILE_SPRITE_TABLE,Y
                STA tile_pixel + 1

                LDA baseaddr
                PHA 
                LDA baseaddr + 1
                PHA

                LDY #15
_loop1          LDA (TILE_PIXEL),Y
                STA (baseaddr),Y
                DEY
                BPL _loop1

                #load_imm $0130, M1
                JSR addition

                LDY #31
_loop2          LDA (TILE_PIXEL),Y
                STA (baseaddr),Y
                DEY
                CPY #15
                BNE _loop2

                PLA 
                STA baseaddr + 1
                PLA
                STA baseaddr

                PLY
                
                RTS

;; A +X+Y inputs
DRAW_TILE_POS   PHY
                PHX
                PHA

                ;; colors
                TAY
                LDA TILE_COLOR_TABLE,Y
                PHA

                ; 40*Y
                #load_imm 0, baseaddr
                LDX #40
                STY M1
                STZ M1+1
_again          JSR addition
                DEX
                BNE _again

                ; color ram base
                #load_imm vid_vram_clr, baseaddr
                JSR addition
                
                ; X
                STX M1
                STZ M1+1
                JSR addition

                PLA
                STA (baseaddr)
                PHY
                LDY #1
                STA (baseaddr),Y
                PLY

                ;; TODO: lower 2

                ;;;;;;;;;;;;

                PLA
                PHA
                ASL
                TAY
                LDA TILE_SPRITE_TABLE,Y
                STA tile_pixel
                INY
                LDA TILE_SPRITE_TABLE,Y
                STA tile_pixel + 1

                ;; calculate baseaddr = $A000 + (x*8) + (y*8*40*2)

                LDY #15
_loop1          LDA (TILE_PIXEL),Y
                STA (baseaddr),Y
                DEY
                BPL _loop1

                #load_imm $0130, M1
                JSR addition

                LDY #31
_loop2          LDA (TILE_PIXEL),Y
                STA (baseaddr),Y
                DEY
                CPY #15
                BNE _loop2

                PLA
                PLX
                PLY
                
                RTS




ADDITION        LDA baseaddr
                CLC
                ADC M1
                STA baseaddr
                LDA baseaddr + 1
                ADC M1 + 1
                STA baseaddr + 1
                RTS




TILE_SPRITE_TABLE 
                .WORD TILE_COVERED
                .WORD TILE_UNCOVERED
                .WORD TILE_MINE

TILE_COLOR_TABLE
                .BYTE $BF
                .BYTE $BF
                .BYTE $0F


TILE_COVERED    
                .byte %00000000
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010

                .byte %00000010
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001

                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %00101010
                .byte %10010101

                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %10101001
                .byte %01010101

TILE_UNCOVERED  
                .byte %10101010
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000

                .byte %10101010
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000

                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000

                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000

TILE_MINE  
                .byte %10101010
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000001

                .byte %10101010
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %01000000

                .byte %10000001
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000

                .byte %01000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000
                .byte %00000000

LAST
.ENDLOGICAL