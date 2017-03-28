.export BlenderConstructor
.export BlenderExecute
.export BlenderDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.tiles.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"
.include "sound.h.asm"

.importzp camera_h, camera_screen
.importzp draw_screen, draw_h, draw_v, draw_frame
.importzp player_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta
.importzp elec_sfx
.importzp values

orig_h = values + $00

.import object_data_extend
;toaster_jump     = object_data_extend + $00
;toaster_jump_low = object_data_extend + $10
;toaster_orig_v   = object_data_extend + $20
;toaster_in_air   = object_data_extend + $30
;toaster_speed     = object_data_extend + $20
;toaster_speed_low = object_data_extend + $30


.segment "CODE"


.proc BlenderConstructor
  ;mov {object_life,x}, #$f0
  ;mov {toaster_in_air,x}, #0
  ;mov {toaster_orig_v,x}, {object_v,x}
  rts
.endproc


.proc BlenderExecute

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  lda #SFX_GOT_HURT
  jsr SoundPlay
  mov player_injury, #30
  mov player_iframe, #100
  mov player_gravity, #$fe
  mov player_gravity_low, #$00
  dec player_health_delta
  dec player_health_delta
Next:
.endscope

Draw:
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

  mov orig_h, draw_h

  ; Left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #BLENDER_FULL_TILE_0
  sta sprite_tile,x
  lda #$02
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  ; Right side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #BLENDER_FULL_TILE_1
  sta sprite_tile,x
  lda #$02
  sta sprite_attr,x

  mov draw_h, orig_h

  lda draw_v
  sec
  sbc #16
  sta draw_v

  ; Top left
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #BLENDER_TOP_TILE
  sta sprite_tile,x
  lda #$00
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  ; Top right.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #BLENDER_TOP_TILE
  sta sprite_tile,x
  lda #$40
  sta sprite_attr,x

Return:
  rts
.endproc


BlenderDraw = BlenderExecute::Draw

