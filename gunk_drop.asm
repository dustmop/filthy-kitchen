.export GunkDropExecute
.export GunkDropDraw
.export gunk_drop_form
.export gunk_drop_inc
.export gunk_drop_speed
.export gunk_drop_speed_low

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.tiles.asm"
.include "object_list.h.asm"
.include "sploosh.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "sound.h.asm"
.include "hurt_player.h.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp draw_screen, draw_h, draw_v, draw_frame
.importzp player_v
.importzp player_iframe
.importzp gloop_sfx
.importzp values

.import object_data_extend
gunk_drop_form      = object_data_extend + $00
gunk_drop_inc       = object_data_extend + $10
gunk_drop_speed     = object_data_extend + $20
gunk_drop_speed_low = object_data_extend + $30


GUNK_DROP_FORM_LIMIT = 10

SPLOOSH_V = $ba


.segment "CODE"


.proc GunkDropExecute

  mov gloop_sfx, #0

.scope FormChange
  lda gunk_drop_form,x
  cmp #2
  bge MoveOkay
  inc gunk_drop_inc,x
  lda gunk_drop_inc,x
  cmp #GUNK_DROP_FORM_LIMIT
  blt AfterMovement
  mov {gunk_drop_inc,x}, #0
  inc gunk_drop_form,x
  lda gunk_drop_form,x
  cmp #2
  bne AfterMovement
  mov gloop_sfx, #$ff
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
  lda object_v,x
  cmp #SPLOOSH_V
  blt Next
  ; sploosh
  mov draw_v, #SPLOOSH_V
  lda object_h,x
  sec
  sbc #4
  sta draw_h
  lda object_screen,x
  sbc #0
  sta draw_screen
  jsr ObjectFree
  jsr ObjectAllocate
  bcc Next
  mov {object_kind,x}, #(OBJECT_KIND_SPLOOSH | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {object_life,x}, #15
  mov {object_step,x}, #0
  mov {object_frame,x}, _
  mov draw_frame, #0
  jsr SplooshExecute
  rts
Next:
.endscope

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  ldy #2
  jsr HurtPlayer
Next:
.endscope


Draw:

  lda gunk_drop_form,x
  sta draw_frame

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

  ; Only play sound effect if gloop is visible on screen.
  lda gloop_sfx
  bpl Return
  lda #SFX_GLOOP
  jsr SoundPlay

Return:
  rts
.endproc


GunkDropDraw = GunkDropExecute::Draw


gunk_drop_frames:
.byte GUNK_DROP_0_TILE
.byte GUNK_DROP_1_TILE
.byte GUNK_DROP_2_TILE
