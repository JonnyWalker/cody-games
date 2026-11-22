; MARK: COPY_ALL_CHAR_TO_MEMORY
; This subroutine copies all tile pixels from ROM to memory by using two 16-Bit pointers.
; Assumes CHAR_ROM_PTR16 (source) is already initialized.
; Assumes CHAR_MEM_PTR16 (destination) is $C800 
; 7*256 Bytes are copied
COPY_ALL_CHAR_TO_MEMORY
    ; set pointer to character memory $C800
    LDA #$00
    STA CHAR_MEM_PTR16+0
    LDA #$C8
    STA CHAR_MEM_PTR16+1

    LDX #0
  _COPY_ALL_CHAR_TO_MEMORY
    LDY #0
  
    ; inner loop
    _COPY_256_CHAR_TO_MEMORY
        LDA (CHAR_ROM_PTR16), Y
        STA (CHAR_MEM_PTR16), Y
        INY
        BNE _COPY_256_CHAR_TO_MEMORY

    ; CHAR_PTR16 += 256 (by inc high byte)
    LDA CHAR_ROM_PTR16 + 1
    INC A
    STA CHAR_ROM_PTR16 + 1

    ; CHAR_MEM_PTR16 += 256 (by inc high byte)
    LDA CHAR_MEM_PTR16 + 1
    INC A
    STA CHAR_MEM_PTR16 + 1

    INX
    CPX #$07
    BNE _COPY_ALL_CHAR_TO_MEMORY
    RTS

; MARK: INIT_SPRITES
INIT_SPRITES
    LDX #0              ; Copy sprite data into video memory
_COPYSPRT   
    LDA SPRITEDATA,X
    STA $A400,X         ; sprite pixel data location. Page 327 and 535 
    INX
    CPX #64
    BNE _COPYSPRT

    LDA #$00            ; Sprite bank 0, white as common sprite color 
    STA VID_SPRC        ; VID_SPRC=$D006 (see codyconstants.asm)
    ; not setting sprite X (SPR0_X) here. handled in SHOW_TITLE_SCREEN
    ; not setting sprite Y (SPR0_Y) here. handled in SHOW_TITLE_SCREEN
    LDA #$11            ; white=1 color 1, white=1 color 2 
    STA SPR0_COL        ; SPR0_COL=$D082 (see codyconstants.asm)
    LDA #$10            ; ($A400-$A000)/$40=$10 see Page 327 for explaination
    STA SPR0_PTR        ; SPR0_PTR=$D083 (see codyconstants.asm)  
    RTS
  