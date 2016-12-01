.export FoodMaybeCreate
.export FoodDispatch

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
.importzp have_spawned_food
.importzp draw_screen
.importzp values
which_food = values + $08

.import object_data_extend
food_kind = object_data_extend + $00


FOOD_KIND_APPLE = 0
FOOD_KIND_STEAK = 1


LIFE_GAIN_APPLE = 2
LIFE_GAIN_STEAK = 5


.segment "CODE"


.proc FoodMaybeCreate
MaybeSpawnApple:
  lda camera_h
  cmp #$80
  blt MaybeSpawnSteak
SpawnApple:
  lda #0
  jsr CreateOnce
MaybeSpawnSteak:
  lda camera_screen
  cmp #$01
  blt Return
  lda camera_h
  cmp #$c0
  blt Return
SpawnSteak:
  lda #1
  jsr CreateOnce
Return:
  rts
.endproc


.proc CreateOnce
  cmp have_spawned_food
  bne Return

  cmp #0
  beq SpawnApple
  bne SpawnSteak

SpawnApple:
  jsr SpawnFood
  bcc Return
  inc have_spawned_food
  mov {object_screen,x}, #$01
  mov {object_h,x}, #$88
  mov {object_v,x}, #$40
  mov {food_kind,x}, #FOOD_KIND_APPLE
  jmp Return

SpawnSteak:
  jsr SpawnFood
  bcc Return
  inc have_spawned_food
  mov {object_screen,x}, #$02
  mov {object_h,x}, #$c8
  mov {object_v,x}, #$40
  mov {food_kind,x}, #FOOD_KIND_STEAK

Return:
  rts
.endproc


.proc SpawnFood
  jsr ObjectAllocate
  bcs Failure
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_FOOD
  mov {object_life,x}, #$ff
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc FoodDispatch

.scope CollisionWithPlayer
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  mov draw_v, {object_v,x}
  mov draw_h, {object_h,x}
  mov draw_screen, {object_screen,x}
  lda food_kind,x
  beq PointsApple
  bne PointsSteak
PointsApple:
  lda #LIFE_GAIN_APPLE
  ldy #POINTS_APPLE
  jmp Okay
PointsSteak:
  lda #LIFE_GAIN_STEAK
  ldy #POINTS_STEAK
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

food_animate_v_offset:
.byte 0
.byte 0
.byte 1
.byte 2
.byte 3
.byte 3
.byte 2
.byte 1


