.export MemoryLayoutInit
.export MemoryLayoutFillChrRam
.exportzp GAMEPLAY0_MEMORY_LAYOUT
.exportzp GAMEPLAY1_MEMORY_LAYOUT
.exportzp BOSS_MEMORY_LAYOUT
.exportzp TITLE_MEMORY_LAYOUT

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "general_mapper.h.asm"

.importzp memory_layout_index
.importzp pointer
.import gameplay0_chr_data, gameplay1_chr_data, chars_chr_data, boss_chr_data
.import title_chr_data

MEMORY_LAYOUT_BANK_GAMEPLAY_CHR = 0
MEMORY_LAYOUT_BANK_SCREEN_CHR = 1
MEMORY_LAYOUT_BANK_MAIN_CODE = 2

MEMORY_LAYOUT_BANK_LEVEL0 = 1
MEMORY_LAYOUT_BANK_LEVEL1 = 2

GAMEPLAY0_MEMORY_LAYOUT = <(gameplay0_info - all_memory_layout_info)
GAMEPLAY1_MEMORY_LAYOUT = <(gameplay1_info - all_memory_layout_info)
BOSS_MEMORY_LAYOUT      = <(boss_info - all_memory_layout_info)
TITLE_MEMORY_LAYOUT     = <(title_info - all_memory_layout_info)


.segment "BOOT"

.proc MemoryLayoutInit
  jsr GeneralMapperInit
  lda #MEMORY_LAYOUT_BANK_MAIN_CODE
  jsr GeneralMapperPrg8000ToC000
  rts
.endproc


; X = gameplay, gameplay_chr + chars_chr
; X = boss,     boss_chr + chars_chr
; X = title,    title_chr + title_chr
.proc MemoryLayoutFillChrRam
  stx memory_layout_index
Loop:
  lda all_memory_layout_info,x
  cmp #$ff
  beq Done
  ; Bank
  jsr GeneralMapperPrg8000ToC000
  inc memory_layout_index
  ; pointer
  ldx memory_layout_index
  lda all_memory_layout_info,x
  sta pointer+0
  inx
  lda all_memory_layout_info,x
  sta pointer+1
  inx
  ; ppu addr
  bit PPU_STATUS
  lda all_memory_layout_info,x
  sta PPU_ADDR
  inx
  lda all_memory_layout_info,x
  sta PPU_ADDR
  inx
  stx memory_layout_index
  ; load $1000
  jsr LoadChrRam
  ldx memory_layout_index
  bne Loop
Done:
  ; Restore bank.
  lda #MEMORY_LAYOUT_BANK_MAIN_CODE
  jsr GeneralMapperPrg8000ToC000
  rts
.endproc


all_memory_layout_info:

gameplay0_info:
.byte MEMORY_LAYOUT_BANK_GAMEPLAY_CHR ; bank_num
.word gameplay0_chr_data ; pointer
.byte $00, $00 ; ppu addr
.byte MEMORY_LAYOUT_BANK_GAMEPLAY_CHR ; bank_num
.word chars_chr_data ; pointer
.byte $10, $00 ; ppu addr
.byte $ff

gameplay1_info:
.byte MEMORY_LAYOUT_BANK_GAMEPLAY_CHR ; bank_num
.word gameplay1_chr_data ; pointer
.byte $00, $00 ; ppu addr
.byte MEMORY_LAYOUT_BANK_GAMEPLAY_CHR ; bank_num
.word chars_chr_data ; pointer
.byte $10, $00 ; ppu addr
.byte $ff

boss_info:
.byte MEMORY_LAYOUT_BANK_GAMEPLAY_CHR ; bank_num
.word boss_chr_data ; pointer
.byte $00, $00 ; ppu addr
.byte MEMORY_LAYOUT_BANK_GAMEPLAY_CHR ; bank_num
.word chars_chr_data ; pointer
.byte $10, $00 ; ppu addr
.byte $ff

title_info:
.byte MEMORY_LAYOUT_BANK_SCREEN_CHR ; bank_num
.word title_chr_data ; pointer
.byte $00, $00 ; ppu addr
.byte MEMORY_LAYOUT_BANK_SCREEN_CHR ; bank_num
.word title_chr_data ; pointer
.byte $10, $00 ; ppu addr
.byte $ff


;X = $80 or $a0
.proc LoadChrRam
  ldx #$10
  ldy #0
Loop:
  lda (pointer),y
  sta PPU_DATA
  iny
  bne Loop
  inc pointer+1
  dex
  bne Loop
  rts
.endproc
