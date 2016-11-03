.export SwatterDispatch

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.const.asm"
.include "object_list.h.asm"
.include "draw_picture.h.asm"
.include "collision_data.h.asm"

.importzp player_has_swatter, player_collision_idx
.importzp player_v, player_h, player_screen
.importzp camera_h

.importzp values

;DrawPicture    values + $00
speed         = values + $01
lifetime      = values + $02
animate_limit = values + $03
num_frames    = values + $04
flip_bits     = values + $05
delta_h       = values + $06
delta_v       = values + $07
delta_screen  = values + $08
collide_dist  = values + $09

.proc SwatterDispatch

Movement:
  ; Move by adding speed.
  lda object_speed,x
  clc
  adc object_h,x
  sta object_h,x
  lda object_speed,x
  bmi MovingLeft
MovingRight:
  lda object_h_screen,x
  adc #0
  sta object_h_screen,x
  jmp DidMovement
MovingLeft:
  lda object_h_screen,x
  sbc #0
  sta object_h_screen,x
DidMovement:

.scope VerticalMovement
  lda object_v,x
  sec
  sbc #$08
  sec
  sbc player_v
  beq Next
  bge ObjectIsDown
ObjectIsAbove:
  lda object_v_low,x
  sec
  sbc #$80
  sta object_v_low,x
  bcs Next
  inc object_v,x
  jmp Next
ObjectIsDown:
  lda object_v_low,x
  clc
  adc #$80
  sta object_v_low,x
  bcc Next
  dec object_v,x
Next:
.endscope

  ; Draw position.
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  mov draw_v, {object_v,x}

  ; Get deltas.
  lda object_v,x
  sec
  sbc player_v
  sta delta_v
  lda object_h,x
  sec
  sbc player_h
  sta delta_h
  lda object_h_screen,x
  sbc player_screen
  sta delta_screen

  ; Maybe collide with player.
.scope CollideWithPlayer
  ldy player_collision_idx
  lda delta_h
  sec
  sbc collision_data_player,y ; h_offset
  bpl AbsoluteH
  eor #$ff
  clc
  adc #1
AbsoluteH:
  iny
  cmp collision_data_player,y ; h_hitbox
  bge Next
  lda delta_v
  sec
  iny
  sbc collision_data_player,y ; v_offset
  bpl AbsoluteV
  eor #$ff
  clc
  adc #1
AbsoluteV:
  iny
  cmp collision_data_player,y ; v_hitbox
  bge Next
  ; Collided.
  mov player_has_swatter, #1
  jsr ObjectFree
  jmp Return
Next:
.endscope

.scope Accelerate
  ; Screen = $00 if swatter is to the right of the player.
  ; Screen = $ff if swatter is to the left of the player.
  lda delta_screen
  beq ObjectToTheRight
ObjectToTheLeft:
  ; If far enough away from player, accelerate at full rate.
  lda delta_h
  cmp #$e0
  blt FullRateFromLeft
  ; If speed is already pointed to the right, accelerate at full rate.
  lda object_speed,x
  bpl FullRateFromLeft
  ; Otherwise, accelerate at partial rate.
  jmp PartialRateFromLeft
FullRateFromLeft:
  lda #($100 - $40)
  jmp AccelerateFromLeft
PartialRateFromLeft:
  lda #($100 - $10)
AccelerateFromLeft:
  clc
  adc object_speed_low,x
  sta object_speed_low,x
  bcs Next
  inc object_speed,x
  jmp Next
ObjectToTheRight:
  ; If far enough away from player, accelerate at full rate.
  lda delta_h
  cmp #$20
  bge FullRateFromRight
  ; If speed is already pointed to the left, accelerate at full rate.
  lda object_speed,x
  bmi FullRateFromRight
  ; Otherwise, accelerate at partial rate.
  jmp PartialRateFromRight
FullRateFromRight:
  lda #$40
  jmp AccelerateFromRight
PartialRateFromRight:
  lda #$10
AccelerateFromRight:
  clc
  adc object_speed_low,x
  sta object_speed_low,x
  bcc Next
  dec object_speed,x
Next:
.endscope

.scope MaximumSpeed
  ; Clamp
  lda object_speed,x
  bmi Negative
Positive:
  cmp #SWATTER_SPEED
  blt Okay
  mov {object_speed,x}, #SWATTER_SPEED
  jmp Okay
Negative:
  cmp #($100 - SWATTER_SPEED)
  bge Okay
  mov {object_speed,x}, #($100 - SWATTER_SPEED)
Okay:
.endscope

  ; Animation.
.scope StepAnimation
  inc object_step,x
  lda object_step,x
  cmp animate_limit
  blt Next
  mov {object_step,x}, #0
  inc object_frame,x
  lda object_frame,x
  cmp num_frames
  blt Next
  mov {object_frame,x}, #0
Next:
.endscope
  ldy object_frame,x
  lda swatter_animation_sequence,y
  sta draw_picture_id
  MovWord draw_picture_pointer, swatter_picture_data
  MovWord draw_sprite_pointer, swatter_sprite_data
  mov draw_palette, #0
  ; Draw the sprites.
  jsr DrawPicture

Return:
  rts
.endproc


swatter_animation_sequence:
.byte $06,$03,$00,$13,$11,$0e,$0b,$08
