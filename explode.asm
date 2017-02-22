.export ExplodeExecute
.export ExplodeDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"
.include "object_list.h.asm"
.include "shared_object_values.asm"

.importzp draw_h, draw_v, draw_screen, draw_frame
.importzp camera_h, camera_v, camera_screen

.segment "CODE"

.proc ExplodeExecute

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

  ; Draw the explode, left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  ldy draw_frame
  lda explode_animation_sequence,y
  sta sprite_tile,x
  lda #$02
  sta sprite_attr,x

  lda draw_h
  clc
  adc #7
  sta draw_h
  bcs Return

  ; Draw the explode, right side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda explode_animation_sequence,y
  sta sprite_tile,x
  lda #$42
  sta sprite_attr,x

Return:
  rts
.endproc


ExplodeDraw = ExplodeExecute::Draw


EXPLODE_ANIMATE_1 = $11
EXPLODE_ANIMATE_2 = $13
EXPLODE_ANIMATE_3 = $15


explode_animation_sequence:
.byte EXPLODE_ANIMATE_1
.byte EXPLODE_ANIMATE_2
.byte EXPLODE_ANIMATE_3
