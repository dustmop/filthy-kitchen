.export PointsDispatch
.export points_digit_ones, points_digit_tens, points_digit_hundreds

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"

.importzp camera_h, camera_screen
.importzp draw_h, draw_v, draw_screen

.import object_data_extend
points_digit_ones = object_data_extend + $00
points_digit_tens = object_data_extend + $10
points_digit_hundreds = object_data_extend + $20

.importzp values
ones_place_tile = values + $08
tens_place_tile = values + $09
hundreds_place_tile = values + $0a

.segment "CODE"


.proc PointsDispatch
  txa
  pha

  dec object_v,x

  ;
  lda points_digit_ones,x
  asl a
  clc
  adc #POINTS_BASE
  sta ones_place_tile
  ;
  lda points_digit_tens,x
  beq :+
  asl a
  clc
  adc #POINTS_BASE
:
  sta tens_place_tile
  ;
  lda points_digit_hundreds,x
  beq :+
  asl a
  clc
  adc #POINTS_BASE
:
  sta hundreds_place_tile

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

  ldy hundreds_place_tile
  beq :+
  jsr DrawSingleDigit
:
  ldy tens_place_tile
  beq :+
  jsr DrawSingleDigit
:
  ldy ones_place_tile
  jsr DrawSingleDigit
  ldy #POINTS_BASE
  jsr DrawSingleDigit
  ldy #POINTS_BASE
  jsr DrawSingleDigit

Return:
  pla
  tax
  rts
.endproc


.proc DrawSingleDigit
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  tya
  sta sprite_tile,x
  lda #1
  sta sprite_attr,x
  lda draw_h
  clc
  adc #6
  sta draw_h
  rts
.endproc


POINTS_BASE = $17


