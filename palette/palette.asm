  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

  ; get ready to write to the palettes in the PPU
  LDA $2002     ; read PPU status to reset the high/low byte
  LDA #$3F      ; load the high byte of the addres #3F10
  STA $2006     ; store that high byte
  LDA #$10      ; load the low byte of the addres #3F10
  STA $2006     ; store that low byte

  ; a succinct way of defining colors for pushing into the palettes
PaletteData:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C 
  ; using a loop, load the values stored in PaletteData into the background and sprite palettes
  LDX #$00       
LoadPalettesLoop:
  LDA PaletteData, x
  STA $2007             ; store the value of the Accumulator in the next memory slot in the PPU (referred to by this 'port' located at $2007)
  INX                   ; incrementing
  CPX #$20              ; is X == 32?
  BNE LoadPalettesLoop

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
 

NMI:
  RTI
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1
