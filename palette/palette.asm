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
  LDX #$00       

; using a loop, load the values stored in PaletteData into the background and sprite palettes
LoadPalettesLoop:
  LDA PaletteData, x
  STA $2007             ; store the value of the Accumulator in the next memory slot in the PPU (referred to by this 'port' located at $2007)
  INX                   ; incrementing
  CPX #$20              ; is X == 32?
  BNE LoadPalettesLoop

; load sprites 
LDA #$00
STA $2003    ; set the low byte of the RAM address
LDA #$02
STA $4014    ; set the high byte of the RAM address

; the DMA (direct memory address) transfer will start automatically after the above is executed.
;
; each sprite needs 4 bytes of data for its position and tile info:
;   1. Y position (vertical) -- $00 is the top, $EF is the bottom
;   2. tile number (0 to 256)
;   3. attributes (color and display info)
;     7 flip vertical
;     6 flip horiz
;     5 priority (0: in front of BG, 1: behind it)
;     1 and 0: color palette of sprite -- choose four of the 16 colors
;   4. X position (horiz)
; there are 64 bytes of sprite memory, four bytes for each of the 16 sprites. They're located at $0200-$02FF.
;
; set up the sprite data
;
LDA #$80
STA $0200      ; put sprite 0 in center ($80) of screen vertically
STA $0203      ; put sprite 0 in center ($80) of screen horizontally
LDA #$00
STA $0201      ; tile number = 0
STA $0202      ; color palette = 0, no flipping

NMI:

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
 

 
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
