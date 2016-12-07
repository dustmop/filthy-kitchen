.export HealthSetMax
.export HealthApplyDelta

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "render_action.h.asm"

.importzp player_health, player_health_delta

HEALTH_FILL_TILE  = $a7
HEALTH_EMPTY_TILE = $a8

HEALTH_MAX = 5

HEALTH_METER_PPU_HIGH = $20
HEALTH_METER_PPU_LOW  = $64


.segment "CODE"

.proc HealthSetMax
  mov player_health, #HEALTH_MAX
  mov player_health_delta, #0
  jmp RenderHealthMeter
.endproc


.proc HealthApplyDelta
  lda player_health_delta
  clc
  adc player_health
  bmi Negative
  cmp #HEALTH_MAX
  blt Okay
Max:
  lda #HEALTH_MAX
  bne Okay
Negative:
  lda #0
Okay:
  sta player_health
  mov player_health_delta, #0
  jsr RenderHealthMeter
  lda player_health
  beq Failure
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc RenderHealthMeter
  lda #5
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #HEALTH_METER_PPU_HIGH
  mov {render_action_addr_low,y}, #HEALTH_METER_PPU_LOW
  ldx #0
Loop:
  cpx player_health
  blt FillOne
EmptyOne:
  mov {render_action_data,y}, #HEALTH_EMPTY_TILE
  bne Increment
FillOne:
  mov {render_action_data,y}, #HEALTH_FILL_TILE
Increment:
  iny
  inx
  cpx #HEALTH_MAX
  blt Loop
  rts
.endproc
