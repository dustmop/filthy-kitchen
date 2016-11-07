.export ScoreAddLow
.export ScoreAddMedium
.export ScoreAddLowNoRender
.export ComboAddLow
.export ComboSetToZero

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "render_action.h.asm"

.importzp score_low, score_medium, combo_low, combo_medium

.segment "CODE"


.proc ScoreAddLow
  jsr ScoreAddLowNoRender
  jsr RenderScore
  rts
.endproc


.proc ScoreAddLowNoRender
  clc
  adc score_low
  sta score_low
  cmp #100
  blt Return
  cmp #200
  blt GreaterThan100
GreaterThan200:
  sec
  sbc #200
  sta score_low
  lda #2
  jmp CarryToMedium
GreaterThan100:
  sec
  sbc #100
  sta score_low
  lda #1
CarryToMedium:
  jsr ScoreAddMedium
Return:
  rts
.endproc


.proc ScoreAddMedium
  clc
  adc score_medium
  sta score_medium
  jsr RenderScore
  rts
.endproc


.proc ComboAddLow
  clc
  adc combo_low
  sta combo_low
  jsr RenderCombo
  rts
.endproc


.proc ComboSetToZero
  mov combo_low, #0
  mov combo_medium, _
  jsr RenderCombo
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


.proc RenderCombo
  txa
  pha
  lda #3
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$20
  mov {render_action_addr_low,y}, #$7c
  lda combo_medium
  jsr NumberToDigits
  sta render_action_data+0,y
  lda combo_low
  jsr NumberToDigits
  sta render_action_data+2,y
  txa
  sta render_action_data+1,y
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
