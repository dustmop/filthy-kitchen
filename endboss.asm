.export EndBossUpdate
.export EndBossFillGraphics

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"


BOSS_LEVEL = $0a


.proc EndBossUpdate
  rts
.endproc


.proc EndBossFillGraphics
  jsr PrepareRenderHorizontal
  ldx #<boss_graphics
  ldy #>boss_graphics
  jsr LoadGraphicsCompressed
  rts
.endproc


boss_graphics:
.include ".b/boss.compressed.asm"
