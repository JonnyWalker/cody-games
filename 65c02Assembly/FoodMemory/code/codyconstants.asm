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

SID_BASE  = $D400               ; SID Voice 1 registers
SID_V1FL  = SID_BASE+0
SID_V1FH  = SID_BASE+1
SID_V1PL  = SID_BASE+2
SID_V1PH  = SID_BASE+3
SID_V1CT  = SID_BASE+4
SID_V1AD  = SID_BASE+5
SID_V1SR  = SID_BASE+6

SID_V2FL  = SID_BASE+7          ; SID Voice 2 registers
SID_V2FH  = SID_BASE+8
SID_V2PL  = SID_BASE+9
SID_V2PH  = SID_BASE+10
SID_V2CT  = SID_BASE+11
SID_V2AD  = SID_BASE+12
SID_V2SR  = SID_BASE+13

SID_V3FL  = SID_BASE+14         ; SID Voice 3 registers
SID_V3FH  = SID_BASE+15
SID_V3PL  = SID_BASE+16
SID_V3PH  = SID_BASE+17
SID_V3CT  = SID_BASE+18
SID_V3AD  = SID_BASE+19
SID_V3SR  = SID_BASE+20

SID_FVOL  = SID_BASE+24         ; SID Volume/Filter register

SID_V3OC  = SID_BASE+27         ; SID Voice 3 oscillator
SID_V3EV  = SID_BASE+28         ; SID Voice 3 envelope
