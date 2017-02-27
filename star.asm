.export StarConstructor
.export StarExecute
.export StarDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"
.include "object_list.h.asm"
.include "shared_object_values.asm"
.include ".b/trig.h.asm"

.importzp draw_h, draw_v, draw_screen, draw_frame
.importzp camera_h, camera_v, camera_screen
.import object_data_extend
star_direction = object_data_extend + $00
star_v_low     = object_data_extend + $10
star_h_low     = object_data_extend + $20


.segment "CODE"


.proc StarConstructor
  tya
  sta object_frame,x
  sta object_step,x
  .repeat 4
  asl a
  .endrepeat
  clc
  adc #3
  sta star_direction,x
  mov {object_life,x}, #$f0
  rts
.endproc


.proc StarExecute

.scope Turn
  lda object_life,x
  cmp #$ed
  bne Next
  dec star_direction,x
  lda star_direction,x
  and #$3f
  sta star_direction,x
  mov {object_life,x}, #$f0
Next:
.endscope

  jsr ApplyMovement
  bcc Return
  jsr ApplyMovement
  bcc Return
  jsr ApplyMovement
  bcc Return

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

  ; Draw the star, left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  ldy draw_frame
  lda star_animation_sequence,y
  sta sprite_tile,x
  lda #$01
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
  lda star_animation_sequence,y
  sta sprite_tile,x
  lda #$c1
  sta sprite_attr,x

Return:
  rts
.endproc


StarDraw = StarExecute


.proc ApplyMovement
  ldy star_direction,x
  lda trig_lookup,y
  tay
HorizontalDelta:
  lda trig_movement,y
  clc
  adc star_h_low,x
  sta star_h_low,x
  iny
  lda trig_movement,y
  bmi ToTheLeft
ToTheRight:
  adc object_h,x
  sta object_h,x
  lda object_screen,x
  adc #0
  sta object_screen,x
  jmp VerticalDelta
ToTheLeft:
  adc object_h,x
  sta object_h,x
  lda object_screen,x
  adc #$ff
  sta object_screen,x
VerticalDelta:
  iny
  lda trig_movement,y
  clc
  adc star_v_low,x
  sta star_v_low,x
  iny
  lda trig_movement,y
  adc object_v,x
  sta object_v,x
  cmp #$f0
  bge Failure
  blt Success
Failure:
  jsr ObjectFree
  clc
  rts
Success:
  sec
  rts
.endproc


STAR_ANIMATE_0 = $af
STAR_ANIMATE_1 = STAR_ANIMATE_0 + 2
STAR_ANIMATE_2 = STAR_ANIMATE_0 + 4


star_animation_sequence:
.byte STAR_ANIMATE_0
.byte STAR_ANIMATE_1
.byte STAR_ANIMATE_2
.byte STAR_ANIMATE_1
