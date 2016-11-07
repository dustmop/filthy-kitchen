.export ScoreAddLow
.export ScoreAddMedium

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "render_action.h.asm"

.importzp score_medium, score_low

.segment "CODE"


.proc ScoreAddLow
  clc
  adc score_low
  sta score_low
  jsr RenderScore
  rts
.endproc


.proc ScoreAddMedium
  rts
.endproc


.proc RenderScore
  txa
  pha
  lda #4
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$20
  mov {render_action_addr_low,y}, #$73
  lda score_medium
  jsr NumberToDigits
  sta render_action_data+1,y
  txa
  sta render_action_data+0,y
  lda score_low
  jsr NumberToDigits
  sta render_action_data+3,y
  txa
  sta render_action_data+2,y
  pla
  tax
  rts
.endproc


.proc NumberToDigits
  ldx #$30
  cmp #80
  blt LessThan80
  sec
  sbc #80
  ldx #$38
LessThan80:
  cmp #40
  blt LessThan40
  sec
  sbc #40
  ldx #$34
LessThan40:
  cmp #20
  blt LessThan20
  sec
  sbc #20
  inx
  inx
LessThan20:
  cmp #10
  blt LessThan10
  sec
  sbc #10
  inx
LessThan10:
  clc
  adc #$30
  rts
.endproc
