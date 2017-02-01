.export EndBossInit
.export EndBossUpdate
.export EndBossFillGraphics
.export EndBossSwatterHandle

.include "include.controller.asm"
.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "hud_display.h.asm"
.include "render_action.h.asm"
.include "object_list.h.asm"
.include "score_combo.h.asm"
.include "sound.h.asm"


.importzp endboss_screen, endboss_count, endboss_state
.importzp endboss_h, endboss_health, endboss_aggro, endboss_speed
.importzp endboss_iframe
.importzp player_owns_swatter
.importzp blink_bg_color
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
  mov endboss_health, #10
  mov endboss_h, #$30
  mov endboss_screen, #$01
  mov endboss_state, #0
  mov endboss_count, #0
  mov endboss_aggro, #0
  rts
.endproc


.proc EndBossUpdate
  lda which_level
  cmp #BOSS_LEVEL
  beq Okay
  rts
Okay:

.scope BlinkBg
  lda blink_bg_color
  beq Break
  dec blink_bg_color
  bne Break
  lda #1
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$3f
  mov {render_action_addr_low,y}, #$00
  mov {render_action_data,y}, #$0f
Break:
.endscope

  lda endboss_state
  beq MovementIntoView
  cmp #1
  beq DriftAndFire
  rts

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
  mov endboss_speed, #$ff
Next:
  jmp Display
.endscope

DriftAndFire:

DriftMovement:
.scope DriftAndFire
  inc endboss_count
  lda endboss_count
  and #$03
  bne AfterDrift
  lda endboss_h
  clc
  adc endboss_speed
  sta endboss_h
AfterDrift:
  lda endboss_count
  cmp #$80
  blt AfterDir
  mov endboss_count, #0
  lda endboss_speed
  eor #$ff
  clc
  adc #1
  sta endboss_speed
AfterDir:
.endscope

Attack:
.scope Attack
  inc endboss_aggro
  lda endboss_aggro
  cmp #$35
  bne Next
  mov endboss_aggro, #0
  ; Fire
  jsr ObjectAllocate
  mov {object_kind,x}, #OBJECT_KIND_DIRTY_SINK
  mov {object_v,x}, #100
  mov {object_h,x}, endboss_h
  mov {object_screen,x}, #0
  ldy #4
  jsr ObjectConstructor
Next:
.endscope

.scope Iframe
  lda endboss_iframe
  beq CanBeHit
  dec endboss_iframe
  jmp Display
.endscope

CanBeHit:
.scope CanBeHit
  ; Is swatter being thrown.
  ldy player_owns_swatter
  bmi Break
  ; Vertical
  lda object_v,y
  cmp #$88
  bge Break
  ; Horizontal
  lda object_h,y
  sec
  sbc endboss_h
  bmi Break
  cmp #$10
  bge Break
  ; Hit the boss
  mov endboss_iframe, #$30
  lda #SFX_FLY_KILLED
  jsr SoundPlay
  lda #10
  jsr ScoreAddLow
  dec endboss_health
  bne Flash
  ; Boss is dead!
  mov endboss_state, #2
  mov endboss_screen, #$01
  mov endboss_h, #$f0
Flash:
  mov blink_bg_color, #2
  lda #1
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$3f
  mov {render_action_addr_low,y}, #$00
  mov {render_action_data,y}, #$16
Break:
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
