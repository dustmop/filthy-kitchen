.export EndBossInit
.export EndBossUpdate
.export EndBossFillGraphics
.export EndBossSwatterHandle
.export EndbossAnimation

.include "include.const.asm"
.include "include.controller.asm"
.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "include.tiles.asm"
.include "gfx.h.asm"
.include "hud_display.h.asm"
.include "render_action.h.asm"
.include "object_list.h.asm"
.include "score_combo.h.asm"
.include "famitone.h.asm"
.include "sound.h.asm"
.include "marque.h.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"
.include "memory_layout.h.asm"


.importzp endboss_screen, endboss_count, endboss_state
.importzp endboss_h, endboss_health, endboss_aggro, endboss_speed
.importzp endboss_iframe, endboss_show_meter, endboss_is_dead
.importzp endboss_render_animation
.importzp endboss_render_animation, endboss_render_count
.importzp player_owns_swatter, player_health, player_h
.importzp blink_bg_color
.importzp bg_x_scroll, bg_nt_select
.importzp draw_h

.importzp which_level
.importzp values
inner = values + $0
outer = values + $1
; Reuse
meter = values + $0


BOSS_LEVEL = MAX_LEVEL

BOSS_HEALTH_PALETTE = 3
BOSS_HEALTH_METER_V = $40


.proc EndBossInit
  lda which_level
  cmp #BOSS_LEVEL
  beq Okay
  rts
Okay:

  mov bg_x_scroll, #$00
  mov bg_nt_select, #$00
  ;
  mov endboss_health, #12
  mov endboss_h, #$30
  mov endboss_screen, #$01
  mov endboss_state, #0
  mov endboss_count, #0
  mov endboss_aggro, #0
  mov endboss_is_dead, #0
  mov endboss_render_animation, #0
  mov endboss_render_count, #0
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
BossDead:
.scope BossDead
  inc endboss_is_dead
  lda endboss_is_dead
  cmp #80
  bne WaitMore
  jmp ExitBoss
WaitMore:
  rts
.endscope

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
  jmp CheckVunerable
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

CheckVunerable:

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
  ; Screen
  lda object_screen,y
  bne Break
  ; Vertical
  lda object_v,y
  cmp #$90
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
  mov endboss_show_meter, #$50
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

PlayerOverlap:
.scope PlayerOverlap
  lda player_health
  beq Break
  ; Kill them.
  lda endboss_screen
  bne Break
  lda player_h
  cmp endboss_h
  blt Break
  ; Play sound effect
  lda #SFX_GOT_HURT
  jsr SoundPlay
  mov player_health, #0
Break:
.endscope

.scope AnimateWings
  inc endboss_render_count
  lda endboss_render_count
  cmp #4
  blt Next
  mov endboss_render_count, #0
  inc endboss_render_animation
  lda endboss_render_animation
  and #1
  ora #$80
  sta endboss_render_animation
Next:
.endscope

.scope DrawHealthMeter
  lda endboss_show_meter
  beq Next
  dec endboss_show_meter

  jsr EndBossFillMeter

  mov draw_h, endboss_h

  ; left edge
  jsr SpriteSpaceAllocate
  lda draw_h
  sta sprite_h,x
  lda #BOSS_HEALTH_METER_V
  sta sprite_v,x
  lda #BOSS_HEALTH_EDGE_TILE
  sta sprite_tile,x
  lda #BOSS_HEALTH_PALETTE
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h

  ldy #0
MeterDrawLoop:
  ; meter 0 edge
  jsr SpriteSpaceAllocate
  lda draw_h
  sta sprite_h,x
  lda #BOSS_HEALTH_METER_V
  sta sprite_v,x
  lda meter,y
  asl a
  clc
  adc #BOSS_HEALTH_METER_BASE_TILE
  sta sprite_tile,x
  lda #BOSS_HEALTH_PALETTE
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h

  iny
  cpy #3
  blt MeterDrawLoop
MeterDrawDone:

  ; right edge
  jsr SpriteSpaceAllocate
  lda draw_h
  sta sprite_h,x
  lda #BOSS_HEALTH_METER_V
  sta sprite_v,x
  lda #BOSS_HEALTH_EDGE_TILE
  sta sprite_tile,x
  lda #(BOSS_HEALTH_PALETTE | $40)
  sta sprite_attr,x

Next:
.endscope

  rts
.endproc


.proc EndBossFillGraphics
  jsr PrepareRenderHorizontal
  ldx #<boss_graphics
  ldy #>boss_graphics
  jsr MemoryLayoutLoadNametable
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


ExitBoss:
  jsr FamiToneMusicStop
  jsr DisableDisplayAndNmi
  inc which_level
  jmp MarqueScreen


.segment "DAT0"


boss_graphics:
.include ".b/boss.compressed.asm"


.segment "BOOT"


.proc EndbossAnimation
  lda endboss_render_animation
  bpl Return
  and #$01
  sta endboss_render_animation
  beq Render0
  bne Render1
Render0:
  jmp BossAnimateWing0
Render1:
  jmp BossAnimateWing1
Return:
  rts
.endproc


BossAnimateWing0:
.include ".b/boss.animate0.asm"


BossAnimateWing1:
.include ".b/boss.animate1.asm"


.proc EndBossFillMeter
  ldx #0
  lda endboss_health
Loop:
  cmp #0
  beq EmptyPiece
  cmp #4
  bge FullPiece
PartialPiece:
  tay
  lda #0
  bpl Assign
EmptyPiece:
  ldy #0
  bpl Assign
FullPiece:
  ldy #4
  sec
  sbc #4
Assign:
  sty meter,x
  inx
  cpx #3
  blt Loop
  rts
.endproc
