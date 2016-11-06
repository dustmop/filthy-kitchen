.export HudSplitAssign
.export HudSplitWait
.export HudDataFill

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"

SPRITE_0_TILE = $2b

.importzp ppu_ctrl_current, bg_x_scroll, bg_nt_select

.segment "CODE"
.proc HudSplitAssign
  mov $200, #19
  mov $201, #SPRITE_0_TILE
  mov $202, #$22
  mov $203, #122
  rts
.endproc

.proc HudSplitWait
Wait0:
  bit PPU_STATUS
  bvs Wait0
Wait1:
  bit PPU_STATUS
  bvc Wait1
  lda bg_x_scroll
  sta PPU_SCROLL
  lda ppu_ctrl_current
  and #$fc
  ora bg_nt_select
  sta PPU_CTRL
  rts
.endproc

.proc HudDataFill
  ;
  lda ppu_ctrl_current
  and #($ff & ~PPU_CTRL_VRAM_INC_32)
  sta ppu_ctrl_current
  sta PPU_CTRL
  ;
  bit PPU_STATUS
  mov PPU_ADDR, #$20
  mov PPU_ADDR, #$00
  ldx #0
NametableLoop:
  lda hud_data,x
  sta PPU_DATA
  inx
  cpx #192
  bne NametableLoop
  ;
  mov PPU_ADDR, #$23
  mov PPU_ADDR, #$c0
  lda #$55
  ldx #0
AttributeLoop:
  sta PPU_DATA
  inx
  cpx #$10
  bne AttributeLoop
  rts
.endproc

hud_data:
.incbin ".b/hud.nametable.dat"
