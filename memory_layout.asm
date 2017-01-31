.export MemoryLayoutInit
.export MemoryLayoutFillChrRam

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "general_mapper.h.asm"

.importzp pointer

MEMORY_LAYOUT_BANK_GAMEPLAY_CHR = 0
MEMORY_LAYOUT_BANK_SCREEN_CHR = 1
MEMORY_LAYOUT_BANK_MAIN_CODE = 2

MEMORY_LAYOUT_NORMAL_POINTER = $80
MEMORY_LAYOUT_BOSS_POINTER = $a0


.segment "BOOT"

.proc MemoryLayoutInit
  jsr GeneralMapperInit
  lda #MEMORY_LAYOUT_BANK_MAIN_CODE
  jsr GeneralMapperPrg8000ToC000
  rts
.endproc


;A = which prg bank to load from
;X = $80 or $a0
.proc MemoryLayoutFillChrRam
  jsr GeneralMapperPrg8000ToC000
  jsr LoadChrRam
  lda #MEMORY_LAYOUT_BANK_MAIN_CODE
  jsr GeneralMapperPrg8000ToC000
  rts
.endproc


;X = $80 or $a0
.proc LoadChrRam
  bit PPU_STATUS
  mov PPU_ADDR, #0
  mov PPU_ADDR, _
  sta pointer+0
  stx pointer+1
  ldx #$20
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
