.export MovementTrig

.include "object_list.h.asm"

.import trig_movement
.import trig_lookup

.import object_data_extend
direction = object_data_extend + $10
pos_h_low = object_data_extend + $20
pos_v_low = object_data_extend + $30


.proc MovementTrig
  ldy direction,x
  lda trig_lookup,y
  tay
HorizontalDelta:
  lda trig_movement,y
  clc
  adc pos_h_low,x
  sta pos_h_low,x
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
  adc pos_v_low,x
  sta pos_v_low,x
  iny
  lda trig_movement,y
  adc object_v,x
  sta object_v,x
  rts
.endproc
