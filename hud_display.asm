.export HudSplitAssign
.export HudSplitWait
.export HudDataFill
.export HudMessagesRender
.export HudElemsPut
.export HudApplyAttributes

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "msg_catalog.h.asm"
.include "memory_layout.h.asm"

SPRITE_0_TILE = $b5

.importzp ppu_ctrl_current, bg_x_scroll, bg_nt_select, lives

.segment "CODE"

.proc HudSplitAssign
  mov $200, #$22
  mov $201, #SPRITE_0_TILE
  mov $202, #$20
  mov $203, #$76
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


HUD_FACE_LEFT_TILE = $45
HUD_FACE_RIGHT_TILE = $47
HUD_HEART_TILE = $2b
HUD_HEART_H = $5b


.proc HudElemsPut
  mov sprite_v   +$0c, #$0f
  mov sprite_tile+$0c, #HUD_FACE_LEFT_TILE
  mov sprite_attr+$0c, #1
  mov sprite_h   +$0c, #$08

  mov sprite_v   +$10, #$0f
  mov sprite_tile+$10, #HUD_FACE_RIGHT_TILE
  mov sprite_attr+$10, #1
  mov sprite_h   +$10, #$10

  lda lives
  beq Done
  cmp #1
  beq LifeNumber1
  cmp #2
  beq LifeNumber2

LifeNumber3:
  mov sprite_v   +$1c, #$11
  mov sprite_tile+$1c, #HUD_HEART_TILE
  mov sprite_attr+$1c, #0
  mov sprite_h   +$1c, #(HUD_HEART_H + 24)

LifeNumber2:
  mov sprite_v   +$18, #$11
  mov sprite_tile+$18, #HUD_HEART_TILE
  mov sprite_attr+$18, #0
  mov sprite_h   +$18, #(HUD_HEART_H + 12)

LifeNumber1:
  mov sprite_v   +$14, #$11
  mov sprite_tile+$14, #HUD_HEART_TILE
  mov sprite_attr+$14, #0
  mov sprite_h   +$14, #(HUD_HEART_H + 0)

Done:
  rts
.endproc


.proc HudDataFill
  jsr PrepareRenderHorizontal
  ldx #<hud_data
  ldy #>hud_data
  jsr MemoryLayoutLoadNametable
  ; Set attributes.
  lda #$55
  jmp HudApplyAttributes
.endproc


.proc HudApplyAttributes
  ldx #$23
  stx PPU_ADDR
  ldx #$c0
  stx PPU_ADDR
  ldx #0
AttributeLoop:
  sta PPU_DATA
  inx
  cpx #$10
  bne AttributeLoop
  rts
.endproc


.proc HudMessagesRender
  ldx #MSG_HEALTH
  jsr MsgRender
  ldx #MSG_LIVES
  jsr MsgRender
  ldx #MSG_SCORE
  jsr MsgRender
  ldx #MSG_COMBO
  jsr MsgRender
  ldx #MSG_ZERO_SCORE
  jsr MsgRender
  ldx #MSG_ZERO_COMBO
  jsr MsgRender
  rts
.endproc


.segment "GFX0"

hud_data:
.include ".b/hud.compressed.asm"
