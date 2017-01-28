.export FlyConstructor
.export FlyListUpdate
.export FlyExecute
.export FlyDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "random.h.asm"
.include "explode.h.asm"
.include "points.h.asm"
.include "score_combo.h.asm"
.include "shared_object_values.asm"
.include ".b/trig.h.asm"

COLLISION_SWATTER_FLY_H_HITBOX = 10
COLLISION_SWATTER_FLY_V_HITBOX = 10

.importzp player_screen, player_h, player_owns_swatter
.importzp player_injury, player_iframe, player_gravity, player_gravity_low
.importzp player_health_delta
.importzp camera_h, camera_screen
.importzp spawn_count
.importzp draw_h, draw_v, draw_screen, draw_frame
.importzp combo_low
.importzp level_has_infinite_flies
.importzp values
adjust_v = values + 0
adjust_h = values + 1
diff_h   = values + 2
is_left  = values + 3
mask     = values + 4
base     = values + 5

.import object_data_extend
fly_direction = object_data_extend + $00
fly_step      = object_data_extend + $10
fly_v_low     = object_data_extend + $20
fly_h_low     = object_data_extend + $30


.segment "CODE"

.proc FlyListUpdate
  bit level_has_infinite_flies
  bmi SpawnFlies
  rts
SpawnFlies:

  inc spawn_count
  lda spawn_count
  cmp #100
  blt Return
  mov spawn_count, #0

  jsr ObjectListCountAvail
  cmp #3
  blt Return

  jsr ObjectAllocate
  bcc Return
  jsr ObjectConstructor
  mov {object_kind,x}, #OBJECT_KIND_FLY
  mov {fly_direction,x}, #$ff
  mov {fly_step,x}, #40

  ; Horizontal position
  lda player_h
  clc
  adc #$60
  sta object_h,x
  lda player_screen
  adc #0
  sta object_screen,x
  ; Vertical position
  jsr RandomGet
  lsr a
  lsr a
  clc
  adc #$60
  sta object_v,x

Return:
  rts
.endproc


.proc FlyConstructor
  mov {fly_direction,x}, #$ff
  mov {fly_step,x}, #40
  rts
.endproc


FLY_SPEED = $110
MAX_WORD = $10000
FLY_MIN_V = $30
FLY_MAX_V = $b0

.proc FlyExecute

.scope MaybeDespawn
  ; If infinite flies, don't use the offscreen despawner.
  bit level_has_infinite_flies
  bmi Next

  jsr ObjectOffscreenDespawn
  bcc Next
  rts
Next:
.endscope

.scope Movement
  ldy fly_direction,x
  bmi Wait
  lda trig_lookup,y
  tay
HorizontalDelta:
  lda trig_movement,y
  clc
  adc fly_h_low,x
  sta fly_h_low,x
  iny
  lda trig_movement,y
  bmi ToTheLeft
ToTheRight:
  adc object_h,x
  sta object_h,x
  lda object_screen,x
  adc #0
  sta object_screen,x
  jmp VerticalDelta
ToTheLeft:
  adc object_h,x
  sta object_h,x
  lda object_screen,x
  adc #$ff
  sta object_screen,x
VerticalDelta:
  iny
  lda trig_movement,y
  clc
  adc fly_v_low,x
  sta fly_v_low,x
  iny
  lda trig_movement,y
  adc object_v,x
  sta object_v,x
CheckOverflow:
  ; check overflow when moving up
  cmp #FLY_MIN_V
  blt MoveUpUnderflow
  ; check overflow when moving down
  cmp #(FLY_MAX_V + 1)
  bge MoveDownOverflow
  jmp Decrement
MoveUpUnderflow:
  mov {object_v,x}, #FLY_MIN_V
  bne RestNow
MoveDownOverflow:
  mov {object_v,x}, #FLY_MAX_V
  bne RestNow
Decrement:
  dec fly_step,x
  lda fly_step,x
  cmp #1
  bne Next
RestNow:
  mov {fly_direction,x}, #$ff
  jsr RandomGet
  and #$1f
  clc
  adc #50
  sta fly_step,x
  jmp Next
Wait:
  dec fly_step,x
  lda fly_step,x
  cmp #1
  bne Next
Pick:
  jsr SetNewDirection
  jsr RandomGet
  and #$1f
  clc
  adc #30
  sta fly_step,x
Next:
.endscope

.scope MaybeDespawnFarAway
  ; Only do this if there are infinite flies.
  bit level_has_infinite_flies
  bpl Next

  lda object_h,x
  sec
  sbc player_h
  lda object_screen,x
  sbc player_screen
  eor #$80
  cmp #$81
  bge Despawn
  cmp #$7f
  blt Despawn
  jmp Next
Despawn:
  jsr ObjectFree
  jmp Return
Next:
.endscope

.scope CollisionWithSwatter
  ldy player_owns_swatter
  bmi Break
  ; Vertical
  lda object_v,x
  sec
  sbc object_v,y
  bpl AbsoluteV
  eor #$ff
  clc
  adc #1
AbsoluteV:
  sta delta_v
  cmp #COLLISION_SWATTER_FLY_V_HITBOX
  bge Break
  ; Horizontal
  lda object_h,x ; fly
  sec
  sbc object_h,y ; swatter
  sta delta_h
  lda object_screen,x ; fly
  sbc object_screen,y ; swatter
  beq HaveDeltaH
  ; If delta_screen is not 0 or -1, collision is out of range.
  cmp #$ff
  bne Break
  lda delta_h
  eor #$ff
  clc
  adc #1
  sta delta_h
HaveDeltaH:
  lda delta_h
  cmp #COLLISION_SWATTER_FLY_H_HITBOX
  bge Break
Collision:
  jsr GainPointsDueToFlyHitByAndSwatter
  jsr ExplodeTheFly
  jmp Return
Break:
.endscope

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  jsr ExplodeTheFly
  mov player_injury, #30
  mov player_iframe, #100
  mov player_gravity, #$fe
  mov player_gravity_low, #$00
  dec player_health_delta
  jmp Return
Next:
.endscope

Draw:

.scope Swivel
  ldy #0
  sty draw_v
  sty draw_h
  lda fly_step,x
  lsr a
  and #$07
  tay
  mov adjust_v, {fly_swivel_v,y}
  mov adjust_h, {fly_swivel_h,y}
Next:
.endscope

  ; Draw position.
  lda object_v,x
  clc
  adc adjust_v
  sta draw_v
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  bne Return

  lda draw_h
  eor #$80
  clc
  adc adjust_h
  eor #$80
  sta draw_h
  bvs Return

  ; Draw the fly.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  ldy draw_frame
  lda fly_animation_sequence,y
  sta sprite_tile,x
  lda #2
  sta sprite_attr,x

Return:
  rts
.endproc


FlyDraw = FlyExecute::Draw


fly_swivel_h:
.byte $00,$ff,$00,$01
fly_swivel_v:
.byte $00,$00,$00,$00,$ff,$00,$01,$00


.proc GainPointsDueToFlyHitByAndSwatter
  lda #1
  jsr ComboAddLow
  lda combo_low
  cmp #9
  blt HaveCombo
MaxCombo:
  lda #9
HaveCombo:
  tay
  mov draw_v, {object_v,x}
  mov draw_h, {object_h,x}
  mov draw_screen, {object_screen,x}
  jsr PointsGainAndCreate
  rts
.endproc


.proc ExplodeTheFly
  mov draw_v, {object_v,x}
  lda object_h,x
  sec
  sbc #8
  sta draw_h
  lda object_screen,x
  sbc #0
  sta draw_screen
  jsr ObjectFree
  jsr ObjectAllocate
  bcc Return
  mov {object_kind,x}, #(OBJECT_KIND_EXPLODE | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {object_life,x}, #15
  mov {object_step,x}, #0
  mov {object_frame,x}, _
  mov draw_frame, #0
  jsr ExplodeExecute
Return:
  rts
.endproc


.proc SetNewDirection
  mov mask, #$3f
  mov base, #0

.scope VerticalRestrict
  lda object_v,x
  cmp #(FLY_MIN_V + $10)
  blt AlwaysMoveDown
  cmp #(FLY_MAX_V - $10)
  bge AlwaysMoveUp
  blt Next
AlwaysMoveDown:
  lsr mask
  mov base, #$20
  bpl Next
AlwaysMoveUp:
  lsr mask
Next:
.endscope

.scope FindHorizontalDiff
  mov is_left, #0
  lda object_h,x
  sec
  sbc player_h
  sta diff_h
  lda object_screen,x
  sbc player_screen
  bpl Next
AbsoluteValue:
  lda diff_h
  eor #$ff
  clc
  adc #1
  sta diff_h
  dec is_left
Next:
.endscope

.scope HorizontalRestrict
  lda diff_h
  cmp #$50
  blt Next
FarAway:
  bit is_left
  bpl AlwaysMoveLeft
AlwaysMoveRight:
  lda base
  clc
  adc #$30
  sta base
  lsr mask
  jmp Next
AlwaysMoveLeft:
  lda base
  clc
  adc #$10
  sta base
  lsr mask
Next:
.endscope

Choose:
  jsr RandomGet
  and mask
  clc
  adc base
  and #$3f
  sta fly_direction,x
  rts
.endproc



FLY_ANIMATE_1 = $0b
FLY_ANIMATE_2 = $0d
FLY_ANIMATE_3 = $0f


fly_animation_sequence:
.byte FLY_ANIMATE_1
.byte FLY_ANIMATE_2
.byte FLY_ANIMATE_3
.byte FLY_ANIMATE_2
