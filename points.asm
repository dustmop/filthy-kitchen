.export PointsGainAndCreate, PointsExecute
.export points_digit_ones, points_digit_tens, points_digit_hundreds
.export combo_points_low, combo_points_medium

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "score_combo.h.asm"

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


.proc PointsGainAndCreate
  jsr PointsCreate
  lda combo_points_low,y
  jsr ScoreAddLowNoRender
  lda combo_points_medium,y
  jsr ScoreAddMedium
  rts
.endproc


.proc PointsCreate
  txa
  pha
  tya
  pha
  jsr ObjectAllocate
  bcc PopStack
  mov {object_kind,x}, #(OBJECT_KIND_POINTS | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {object_life,x}, #40
  mov {object_step,x}, #0
  mov {object_frame,x}, _
  mov {points_digit_ones,x}, {ones_place,y}
  mov {points_digit_tens,x}, {tens_place,y}
  mov {points_digit_hundreds,x}, {hundreds_place,y}
  jsr PointsExecute
PopStack:
  pla
  tay
  pla
  tax
  rts
.endproc


combo_points_low:
.byte 1, 1, 2, 4, 8, 16, 32, 64, 28, 56, 20, 50
combo_points_medium:
hundreds_place:
.byte 0, 0, 0, 0, 0,  0,  0,  0,  1,  2,  0,  0
tens_place:
.byte 0, 0, 0, 0, 0,  1,  3,  6,  2,  5,  2,  5
ones_place:
.byte 1, 1, 2, 4, 8,  6,  2,  4,  8,  6,  0,  0


POINTS_APPLE = 10
POINTS_STEAK = 11


.proc PointsExecute
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


PointsExecute_Return = PointsExecute::Return


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
  bcs StopDrawing
  sta draw_h
  rts
StopDrawing:
  pla
  pla
  lda #>(PointsExecute_Return - 1)
  pha
  lda #<(PointsExecute_Return - 1)
  pha
  rts
.endproc


POINTS_BASE = $17


