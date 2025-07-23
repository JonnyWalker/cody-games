ADDR      = $0300               ; The actual loading address of the program

SCRRAM1   = $A000               ; Screen memory locations for double-buffering
SCRRAM2   = $A400

COLRAM1   = $A800               ; Color memory locations for double-buffering
COLRAM2   = $AC00

SPRITES   = $B000               ; Sprite memory locations

VIA_BASE  = $9F00               ; VIA base address and register locations
VIA_IORB  = VIA_BASE+$0
VIA_IORA  = VIA_BASE+$1
VIA_DDRB  = VIA_BASE+$2
VIA_DDRA  = VIA_BASE+$3
VIA_T1CL  = VIA_BASE+$4
VIA_T1CH  = VIA_BASE+$5
VIA_SR    = VIA_BASE+$A
VIA_ACR   = VIA_BASE+$B
VIA_PCR   = VIA_BASE+$C
VIA_IFR   = VIA_BASE+$D
VIA_IER   = VIA_BASE+$E

VID_BLNK  = $D000               ; Video blanking status register
VID_CNTL  = $D001               ; Video control register
VID_COLR  = $D002               ; Video color register
VID_BPTR  = $D003               ; Video base pointer register
VID_SCRL  = $D004               ; Video scroll register
VID_SCRC  = $D005               ; Video screen common colors register
VID_SPRC  = $D006               ; Video sprite control register

SPR0_X    = $D080               ; Sprite X coordinate
SPR0_Y    = $D081               ; Sprite Y coordinate
SPR0_COL  = $D082               ; Sprite color
SPR0_PTR  = $D083               ; Sprite base pointer

SID_BASE  = $D400               ; SID registers (mostly for voice 1)
SID_V1FL  = SID_BASE+0
SID_V1FH  = SID_BASE+1
SID_V1PL  = SID_BASE+2
SID_V1PH  = SID_BASE+3
SID_V1CT  = SID_BASE+4
SID_V1AD  = SID_BASE+5
SID_V1SR  = SID_BASE+6
SID_FVOL  = SID_BASE+24
