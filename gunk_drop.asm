.export GunkDropExecute
.export gunk_drop_form
.export gunk_drop_inc
.export gunk_drop_speed
.export gunk_drop_speed_low

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp draw_screen, draw_h, draw_v
.importzp player_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta
.importzp values

.import object_data_extend
gunk_drop_form      = object_data_extend + $00
gunk_drop_inc       = object_data_extend + $10
gunk_drop_speed     = object_data_extend + $20
gunk_drop_speed_low = object_data_extend + $30


GUNK_DROP_0_TILE = $85
GUNK_DROP_1_TILE = $87
GUNK_DROP_2_TILE = $89
GUNK_DROP_FORM_LIMIT = 10


.segment "CODE"


.proc GunkDropExecute

.scope FormChange
  lda gunk_drop_form,x
  sta draw_frame
  cmp #2
  bge MoveOkay
  inc gunk_drop_inc,x
  lda gunk_drop_inc,x
  cmp #GUNK_DROP_FORM_LIMIT
  blt AfterMovement
  mov {gunk_drop_inc,x}, #0
  inc gunk_drop_form,x
  jmp AfterMovement
MoveOkay:
.endscope

.scope Movement
  lda gunk_drop_speed_low,x
  clc
  adc #$20
  sta gunk_drop_speed_low,x
  lda gunk_drop_speed,x
  adc #0
  sta gunk_drop_speed,x
  clc
  adc object_v,x
  sta object_v,x
.endscope

AfterMovement:

.scope CollisionWithBackground
  ; TODO
.endscope

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  mov player_injury, #30
  mov player_iframe, #100
  mov player_gravity, #$fe
  mov player_gravity_low, #$00
  dec player_health_delta
  dec player_health_delta
Next:
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

  ; Draw the utensils, left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  ldy draw_frame
  lda gunk_drop_frames,y
  sta sprite_tile,x
  lda #$03
  sta sprite_attr,x

Return:
  rts
.endproc


gunk_drop_frames:
.byte GUNK_DROP_0_TILE
.byte GUNK_DROP_1_TILE
.byte GUNK_DROP_2_TILE