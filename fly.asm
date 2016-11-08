.export FlyListUpdate
.export FlyDispatch

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

COLLISION_SWATTER_FLY_H_HITBOX = 10
COLLISION_SWATTER_FLY_V_HITBOX = 10

.importzp player_screen, player_h, player_owns_swatter
.importzp camera_h, camera_screen
.importzp spawn_count
.importzp draw_h, draw_v, draw_screen
.importzp combo_low

.segment "CODE"

.proc FlyListUpdate
  inc spawn_count
  lda spawn_count
  cmp #100
  blt Return
  mov spawn_count, #0

  jsr ObjectListCountAvail
  cmp #2
  blt Return

  jsr ObjectAllocate
  bcs Return
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_FLY
  mov {object_life,x}, #$ff

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


.proc FlyDispatch
  txa
  pha

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

  ; Draw position.
  mov draw_v, {object_v,x}
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  bne Return

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
  pla
  tax
  rts
.endproc


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
  ; Create points object
  mov draw_v, {object_v,x}
  mov draw_h, {object_h,x}
  mov draw_screen, {object_screen,x}
  txa
  pha
  tya
  pha
  jsr ObjectAllocate
  bcs PopStack
  mov {object_kind,x}, #(OBJECT_KIND_POINTS | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {object_life,x}, #40
  mov {object_step,x}, #0
  mov {object_frame,x}, _
  mov {points_digit_ones,x}, {ones_place,y}
  mov {points_digit_tens,x}, {tens_place,y}
  mov {points_digit_hundreds,x}, {hundreds_place,y}
  jsr PointsDispatch
PopStack:
  pla
  tay
  pla
  tax
  ;
  lda combo_points_low,y
  jsr ScoreAddLowNoRender
  lda combo_points_medium,y
  jsr ScoreAddMedium
  rts
.endproc


combo_points_low:
.byte 1, 1, 2, 4, 8, 16, 32, 64, 28, 56
combo_points_medium:
hundreds_place:
.byte 0, 0, 0, 0, 0,  0,  0,  0,  1,  2
tens_place:
.byte 0, 0, 0, 0, 0,  1,  3,  6,  2,  5
ones_place:
.byte 1, 1, 2, 4, 8,  6,  2,  4,  8,  6


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
  mov {object_kind,x}, #(OBJECT_KIND_EXPLODE | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {object_life,x}, #15
  mov {object_step,x}, #0
  mov {object_frame,x}, _
  mov draw_frame, #0
  jsr ExplodeDispatch
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
