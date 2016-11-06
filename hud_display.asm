.export HudSplitAssign
.export HudSplitWait
.export HudDataFill
.export HudElemsPut

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.sys.asm"

SPRITE_0_TILE = $2b

.importzp ppu_ctrl_current, bg_x_scroll, bg_nt_select

.segment "CODE"
.proc HudSplitAssign
  mov $200, #19
  mov $201, #SPRITE_0_TILE
  mov $202, #$20
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


HUD_FACE_LEFT = $3b
HUD_FACE_RIGHT = $3d
HUD_HEART = $2d


.proc HudElemsPut
  mov sprite_v   +$0c, #$0f
  mov sprite_tile+$0c, #HUD_FACE_LEFT
  mov sprite_attr+$0c, #1
  mov sprite_h   +$0c, #$08

  mov sprite_v   +$10, #$0f
  mov sprite_tile+$10, #HUD_FACE_RIGHT
  mov sprite_attr+$10, #1
  mov sprite_h   +$10, #$10

  mov sprite_v   +$14, #$11
  mov sprite_tile+$14, #HUD_HEART
  mov sprite_attr+$14, #0
  mov sprite_h   +$14, #$62

  mov sprite_v   +$18, #$11
  mov sprite_tile+$18, #HUD_HEART
  mov sprite_attr+$18, #0
  mov sprite_h   +$18, #$6f

  mov sprite_v   +$1c, #$11
  mov sprite_tile+$1c, #HUD_HEART
  mov sprite_attr+$1c, #0
  mov sprite_h   +$1c, #$7c
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
