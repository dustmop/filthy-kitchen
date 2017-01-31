.export EndBossUpdate
.export EndBossFillGraphics
.export EndBossSwatterHandle

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "hud_display.h.asm"
.include "render_action.h.asm"


.importzp bg_x_scroll, bg_nt_select
.importzp values
inner = values + $0
outer = values + $1


BOSS_LEVEL = $0a


.proc EndBossUpdate
  mov bg_x_scroll, #$00
  mov bg_nt_select, #$01
  rts
.endproc


.proc EndBossFillGraphics
  jsr PrepareRenderHorizontal
  ldx #<boss_graphics
  ldy #>boss_graphics
  jsr LoadGraphicsCompressed
  lda #$ff
  jsr HudApplyAttributes
  jsr RemoveLeftBackground
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


.proc EndBossSwatterHandle
  ; Palette for swatter.
  lda #1
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$3f
  mov {render_action_addr_low,y},  #$12
  mov {render_action_data,y},      #$10
  rts
.endproc


.proc RemoveLeftBackground
  mov PPU_ADDR, #$20
  mov PPU_ADDR, #$c0
  mov outer, #$03
  mov inner, #$40
  lda #0
Loop:
  sta PPU_DATA
  dec inner
  bne Loop
  dec outer
  bne Loop
  rts
.endproc


boss_graphics:
.include ".b/boss.compressed.asm"
