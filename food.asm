.export FoodConstructor
.export FoodExecute

.export food_kind

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "random.h.asm"
.include "points.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"
.include ".b/pictures.h.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp draw_screen
.importzp values
which_food = values + $08

.import object_data_extend
food_kind = object_data_extend + $00


FOOD_KIND_APPLE = 0
FOOD_KIND_STEAK = 1
FOOD_KIND_GRAPES = 2
FOOD_KIND_ICE_CREAM = 3


LIFE_GAIN_APPLE = 2
LIFE_GAIN_STEAK = 5
LIFE_GAIN_GRAPES = 2
LIFE_GAIN_ICE_CREAM = 1


.segment "CODE"


.proc FoodConstructor
  tya
  sta food_kind,x
  rts
.endproc


.proc FoodExecute

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope CollisionWithPlayer
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  mov draw_v, {object_v,x}
  mov draw_h, {object_h,x}
  mov draw_screen, {object_screen,x}
  lda food_kind,x
  beq PointsApple
  cmp #FOOD_KIND_STEAK
  beq PointsSteak
  cmp #FOOD_KIND_GRAPES
  beq PointsGrapes
  bne PointsIceCream
PointsApple:
  lda #LIFE_GAIN_APPLE
  ldy #POINTS_APPLE
  jmp Okay
PointsSteak:
  lda #LIFE_GAIN_STEAK
  ldy #POINTS_STEAK
  jmp Okay
PointsGrapes:
  lda #LIFE_GAIN_GRAPES
  ldy #POINTS_GRAPES
  jmp Okay
PointsIceCream:
  lda #LIFE_GAIN_ICE_CREAM
  ldy #POINTS_ICE_CREAM
Okay:
  clc
  adc player_health_delta
  sta player_health_delta
  jsr PointsGainAndCreate
  jsr ObjectFree
  jmp Return
Next:
.endscope

  ; First part of food appears in the background of the later part.
  jsr SpriteSpaceSetLowPriority

  ; Draw position.
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  ldy object_frame,x
  lda food_animate_v_offset,y
  clc
  adc object_v,x
  sta draw_v

  ; Animation.
  ldy food_kind,x
  lda food_picture,y
  sta draw_picture_id
  MovWord draw_picture_pointer, food_picture_data
  MovWord draw_sprite_pointer, food_sprite_data
  mov draw_palette, #0
  ; Draw the sprites.
  jsr DrawPicture

Return:
  rts
.endproc


food_picture:
.byte PICTURE_ID_FOOD_APPLE_OUTER
.byte PICTURE_ID_FOOD_STEAK_OUTER
.byte PICTURE_ID_FOOD_GRAPES_OUTER
.byte PICTURE_ID_FOOD_ICE_CREAM_OUTER

food_animate_v_offset:
.byte 0
.byte 0
.byte 1
.byte 2
.byte 3
.byte 3
.byte 2
.byte 1


