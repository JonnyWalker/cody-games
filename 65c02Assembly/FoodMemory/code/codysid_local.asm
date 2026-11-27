;
; codysid_local.asm
; A simple SID file player embedded at assembly time on the Cody Computer.
;
; Based on codysid.asm, Copyright 2024 Frederick John Milens III, The Cody Computer Developers.
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 3
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
;
; Only supports PSID version 2, and even then it's best not to get your hopes up.
; Aside from the SID location the Cody Computer's memory map is completely different
; from the C64, and many SID files that "should work" do not. Some work but corrupt
; the screen.
;
; See https://gist.github.com/cbmeeks/2b107f0a8d36fc461ebb056e94b2f4d6 for a
; description of the various SID file layouts.
; 
; name of SID-file must be specified at the end of this program.

SIDBASE   = $D400               ; SID register base address

ISRPTR    = $08                 ; Pointer to the ISR address zero page variable


SIDHEAD   = $4000               ; Page to store the SID file header, must match the SID-files start address.
SIDLOAD   = SIDHEAD+$00
SIDINIT   = SIDHEAD+$00
SIDPLAY   = SIDHEAD+$03
SONGNUM   = 0

;
; MAIN
;
; Main loop of the SID player.
;
CODYSID_LOCAL_MAIN        SEI
            JSR STOPSID         ; Not playing by default

            LDA #SONGNUM
            JSR SIDINIT    
            
            LDA #<TIMERISR      ; Set up timer ISR location
            STA ISRPTR+0
            LDA #>TIMERISR
            STA ISRPTR+1
            
            LDA #<20000         ; Set up VIA timer 1 to emit ticks for timing purposes
            STA VIA_T1CL
            LDA #>20000
            STA VIA_T1CH
  
            LDA #$40            ; Set up VIA timer 1 continuous interrupts, no outputs
            STA VIA_ACR
  
            LDA #$C0            ; Enable VIA timer 1 interrupt
            STA VIA_IER
            
            CLI                 ; Turn on interrupts
            RTS

;
; STOPSID
;
; Stops the currently playing SID.
;
STOPSID     LDA #0
            LDX #0
_LOOP       STA SIDBASE,X
            INX
            CPX #25
            BNE _LOOP
            RTS

;
; TIMERISR
;
; A timer interrupt handler that calls the SID's play routine.
;
TIMERISR    BIT VIA_T1CL          ; Clear 65C22 interrupt by reading

            PHA                   ; Preserve registers
            PHX
            PHY
          
            JSR SIDPLAY         ; Call the play routine
          
_DONE       PLY                   ; Restore registers
            PLX
            PLA
          
            RTI                   ; All done

            .cerror * > SIDLOAD, "SID-address in player code"
            .fill SIDLOAD - *, 0        ; fill with zero
            .binary "greensleeves.sid", $7E     ; skip header