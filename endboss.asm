.export EndBossUpdate
.export EndBossFillGraphics

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "hud_display.h.asm"


BOSS_LEVEL = $0a


.proc EndBossUpdate
  rts
.endproc


.proc EndBossFillGraphics
  jsr PrepareRenderHorizontal
  ldx #<boss_graphics
  ldy #>boss_graphics
  jsr LoadGraphicsCompressed
  lda #$ff
  jsr HudApplyAttributes
  ; Collision
  lda #$55
  ldx #$0
Loop:
  sta $5c0,x
  inx
  cpx #$10
  bne Loop
  rts
.endproc


boss_graphics:
.include ".b/boss.compressed.asm"
