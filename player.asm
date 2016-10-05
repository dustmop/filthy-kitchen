.export PlayerInit
.export PlayerUpdate
.export PlayerDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.controller.asm"
.include "include.sprites.asm"

.importzp player_v, player_h, player_h_low, player_on_ground
.importzp player_jump, player_jump_low
.importzp buttons
.importzp values

PLAYER_TILE = $00
SPEED_LOW  = $60
SPEED_HIGH = $01

offset_v     = values + $00
offset_h     = values + $01
offset_tile  = values + $02
is_on_ground = values + $03


.segment "CODE"


.proc PlayerInit
  mov player_v, #$a0
  mov player_h, #$40
  mov player_jump, #$00
  rts
.endproc


.proc PlayerUpdate

.scope CheckGround
  ; Check if player is standing on the ground.
  lda player_v
  cmp #$a0
  bge IsOnGround
NotOnGround:
  mov is_on_ground, #$ff
  jmp Next
IsOnGround:
  mov player_v, #$a0
  mov is_on_ground, #$00
  mov player_jump, #$00
Next:
.endscope

.scope HandleJump
  lda buttons
  and #BUTTON_A
  beq Next
MaybeJump:
  bit is_on_ground
  bmi Next
Jump:
  mov player_jump, #$fc
  mov player_jump_low, #0
Next:
.endscope

.scope Gravity
  ; Gravity.
  lda player_jump
  clc
  adc player_v
  sta player_v
  inc player_jump_low
  lda player_jump_low
  cmp #5
  blt Next
  mov player_jump_low, #0
  inc player_jump
Next:
.endscope

.scope MaybeLeftOrRight
  lda buttons
  and #BUTTON_LEFT
  bne MoveLeft
  lda buttons
  and #BUTTON_RIGHT
  bne MoveRight
  beq Next
MoveLeft:
  lda player_h_low
  sec
  sbc #SPEED_LOW
  sta player_h_low
  lda player_h
  sbc #SPEED_HIGH
  sta player_h
  jmp Next
MoveRight:
  lda player_h_low
  clc
  adc #SPEED_LOW
  sta player_h_low
  lda player_h
  adc #SPEED_HIGH
  sta player_h
Next:
.endscope

  rts
.endproc


.proc PlayerDraw
  ldx #$00

  lda #(PLAYER_TILE + 1)
  sta offset_tile

  ; Row 0,1
  mov offset_v, player_v
  dec offset_v
  mov offset_h, player_h
  jsr DrawSingleTile
  jsr DrawRightSideTile

  ; Row 2,3
  inc offset_tile
  inc offset_tile
  lda offset_v
  clc
  adc #$10
  sta offset_v
  mov offset_h, player_h
  .repeat 4
  inx
  .endrepeat
  jsr DrawSingleTile
  fallt DrawRightSideTile
.endproc


.proc DrawRightSideTile
  inc offset_tile
  inc offset_tile
  lda offset_h
  clc
  adc #8
  sta offset_h
  .repeat 4
  inx
  .endrepeat
  fallt DrawSingleTile
.endproc


.proc DrawSingleTile
  mov {sprite_v,x}, offset_v
  mov {sprite_tile,x}, offset_tile
  mov {sprite_attr,x}, #$00
  mov {sprite_h,x}, offset_h
  rts
.endproc
