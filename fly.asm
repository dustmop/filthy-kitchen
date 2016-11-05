.export FlyListUpdate
.export FlyDispatch

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "random.h.asm"
.include "shared_object_values.asm"

COLLISION_SWATTER_FLY_H_HITBOX = 10
COLLISION_SWATTER_FLY_V_HITBOX = 10

.importzp player_screen, player_h, player_owns_swatter
.importzp camera_h, camera_screen
.importzp spawn_count
.importzp draw_h, draw_v, draw_screen

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


FLY_ANIMATE_1 = $0b
FLY_ANIMATE_2 = $0d
FLY_ANIMATE_3 = $0f


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
  jsr ObjectFree
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


fly_animation_sequence:
.byte FLY_ANIMATE_1
.byte FLY_ANIMATE_2
.byte FLY_ANIMATE_3
.byte FLY_ANIMATE_2
