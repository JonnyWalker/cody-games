.cpu            "65c02"

                                            ; TODO: update "magic numberes" inside comments

INITIALIZATION
                LDA VID_CTRL_REG            ; enable bitmapped
                ORA #$10                    ; graphics mode
                STA VID_CTRL_REG            ;
                LDA #$0C                    ;
                STA VID_CTRL_SHC            ;
                
                LDA #$EC                    ; high nibble: color RAM location -> $D800 (14 KiB offset from $A000)
                STA VID_CTRL_CLR            ; low  nibble: border color code  -> white
                LDA #$0F                    ; high nibble: pixel RAM location -> $A000 (00 KiB offset from $A000)
                STA VID_CTRL_PXL            ; low  nibble: character RAM (not used)

                ; initializing color RAM
                #load_imm VID_VRAM_CLR, $C0 ;
                LDA #$BF                    ;
                LDX #4                      ;
                                            ;
_loopX          LDY #0                      ;
_loopY          STA ($C0),Y                 ;
                INY                         ;
                BNE _loopY                  ;
                                            ;
                INC $C0 + 1                 ;
                DEX                         ;
                BNE _loopX                  ;

                RTS