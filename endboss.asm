.export EndBossInit
.export EndBossUpdate
.export EndBossFillGraphics
.export EndBossSwatterHandle

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "hud_display.h.asm"
.include "render_action.h.asm"


.importzp endboss_screen, endboss_count, endboss_state
.importzp endboss_h, endboss_health
.importzp bg_x_scroll, bg_nt_select
.importzp which_level
.importzp values
inner = values + $0
outer = values + $1


BOSS_LEVEL = $04


.proc EndBossInit
  lda which_level
  cmp #BOSS_LEVEL
  beq Okay
  rts
Okay:

  mov bg_x_scroll, #$00
  mov bg_nt_select, #$00
  ;
  mov endboss_health, #16
  mov endboss_h, #$30
  mov endboss_screen, #$01
  mov endboss_state, #0
  mov endboss_count, #0
  rts
.endproc


.proc EndBossUpdate
  lda which_level
  cmp #BOSS_LEVEL
  beq Okay
  rts
Okay:

  lda endboss_state
  beq MovementIntoView
  bne Display

MovementIntoView:
.scope MovementIntoView
  lda endboss_h
  beq Underflow
  dec endboss_h
  jmp State
Underflow:
  dec endboss_h
  dec endboss_screen
State:
  lda endboss_h
  cmp #$90
  bne Next
  mov endboss_state, #1
Next:
.endscope

Display:
  lda #$30
  sec
  sbc endboss_h
  sta bg_x_scroll
  lda #$01
  sbc endboss_screen
  sta bg_nt_select
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
