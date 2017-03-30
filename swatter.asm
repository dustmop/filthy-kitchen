.export SwatterExecute
.export SwatterDraw
.export swatter_speed

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.const.asm"
.include "object_list.h.asm"
.include "draw_picture.h.asm"
.include "score_combo.h.asm"
.include "shared_object_values.asm"
.include ".b/pictures.h.asm"
.include "sound.h.asm"

.importzp player_owns_swatter, player_collision_idx
.importzp player_v, player_h, player_screen, player_iframe
.importzp draw_screen, draw_frame
.importzp camera_h, camera_screen
.importzp combo_low

.import object_data_extend
swatter_speed     = object_data_extend + $00
swatter_speed_low = object_data_extend + $10
swatter_v_low     = object_data_extend + $20
swatter_frame     = object_data_extend + $30
.export swatter_speed, swatter_speed_low, swatter_v_low


.proc SwatterExecute

  mov delta_h, {swatter_speed,x}
  mov delta_v, #0

.scope VerticalAcceleration
  lda object_v,x
  sec
  sbc #$08
  sec
  sbc player_v
  beq Next
  bge ObjectIsDown
ObjectIsAbove:
  lda swatter_v_low,x
  sec
  sbc #$80
  sta swatter_v_low,x
  bcs Next
  inc delta_v
  jmp Next
ObjectIsDown:
  lda swatter_v_low,x
  clc
  adc #$80
  sta swatter_v_low,x
  bcc Next
  dec delta_v
Next:
.endscope

  jsr ObjectMovementApplyDelta

  ; Player deltas also used for seeking behavior.
.scope CheckCollision
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  ; If invincible, there are no consequences.
  lda player_iframe
  bne Next
  mov player_owns_swatter, #$ff
  ; Play the sound effect to signify the combo ending.
.scope MoreThanTwo
  lda combo_low
  cmp #2
  blt Next
  lda #SFX_MAKE_STARS
  jsr SoundPlay
Next:
.endscope
  jsr ComboSetToZero
  jsr ObjectFree
  jmp Return
Next:
.endscope

.scope Accelerate
  ; Screen = $00 if swatter is to the right of the player.
  ; Screen = $ff if swatter is to the left of the player.
  lda delta_dir
  beq ObjectToTheRight
ObjectToTheLeft:
  ; If far enough away from player, accelerate at full rate.
  lda delta_h
  cmp #$20
  bge FullRateFromLeft
  ; If speed is already pointed to the right, accelerate at full rate.
  lda swatter_speed,x
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
  adc swatter_speed_low,x
  sta swatter_speed_low,x
  bcs Next
  inc swatter_speed,x
  jmp Next
ObjectToTheRight:
  ; If far enough away from player, accelerate at full rate.
  lda delta_h
  cmp #$20
  bge FullRateFromRight
  ; If speed is already pointed to the left, accelerate at full rate.
  lda swatter_speed,x
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
  adc swatter_speed_low,x
  sta swatter_speed_low,x
  bcc Next
  dec swatter_speed,x
Next:
.endscope

.scope MaximumSpeed
  ; Clamp
  lda swatter_speed,x
  bmi Negative
Positive:
  cmp #SWATTER_MAX_SPEED
  blt Okay
  mov {swatter_speed,x}, #SWATTER_MAX_SPEED
  jmp Okay
Negative:
  cmp #($100 - SWATTER_MAX_SPEED)
  bge Okay
  mov {swatter_speed,x}, #($100 - SWATTER_MAX_SPEED)
Okay:
.endscope

  mov {swatter_frame,x}, draw_frame

Draw:

  ; Draw position.
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  mov draw_v, {object_v,x}

  ; Animation.
  ldy swatter_frame,x
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


SwatterDraw = SwatterExecute::Draw


swatter_animation_sequence:
.byte PICTURE_ID_SWATTER_RIGHT
.byte PICTURE_ID_SWATTER_DOWN_RIGHT
.byte PICTURE_ID_SWATTER_DOWN
.byte PICTURE_ID_SWATTER_DOWN_LEFT
.byte PICTURE_ID_SWATTER_LEFT
.byte PICTURE_ID_SWATTER_UP_LEFT
.byte PICTURE_ID_SWATTER_UP
.byte PICTURE_ID_SWATTER_UP_RIGHT
