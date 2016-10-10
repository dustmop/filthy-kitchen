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

SWATTER_TILE = $02
PLAYER_TILE = $16
PLAYER_TILE_BOTTOM = $1a
SPEED_LOW  = $60
SPEED_HIGH = $01

BOTTOM_FLOOR = $a8

draw_v       = values + $00
draw_h       = values + $01
draw_tile    = values + $02
draw_attr    = values + $03
is_on_ground = values + $04


.segment "CODE"


.proc PlayerInit
  mov player_v, #BOTTOM_FLOOR
  mov player_h, #$10
  mov player_jump, #$00
  rts
.endproc


.proc PlayerUpdate

.scope CheckGround
  ; Check if player is standing on the ground.
  lda player_v
  cmp #BOTTOM_FLOOR
  bge IsOnGround
NotOnGround:
  mov is_on_ground, #$ff
  jmp Next
IsOnGround:
  mov player_v, #BOTTOM_FLOOR
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

  mov draw_tile, #(SWATTER_TILE + 1)
  mov draw_attr, #0

  ; Swatter
  lda player_v
  clc
  adc #8
  sta draw_v
  lda player_h
  clc
  adc #6
  sta draw_h
  jsr DrawSingleTile
  jsr DrawRightSideTile

  mov draw_tile, #(PLAYER_TILE + 1)
  inc draw_attr
  .repeat 4
  inx
  .endrepeat

  ; Row 0,1
  mov draw_v, player_v
  dec draw_v
  mov draw_h, player_h
  jsr DrawSingleTile
  jsr DrawRightSideTile

  mov draw_tile, #(PLAYER_TILE_BOTTOM + 1)
  inc draw_attr
  .repeat 4
  inx
  .endrepeat

  ; Row 2,3
  lda draw_v
  clc
  adc #$10
  sta draw_v
  mov draw_h, player_h
  jsr DrawSingleTile
  fallt DrawRightSideTile
.endproc


.proc DrawRightSideTile
  inc draw_tile
  inc draw_tile
  lda draw_h
  clc
  adc #8
  sta draw_h
  .repeat 4
  inx
  .endrepeat
  fallt DrawSingleTile
.endproc


.proc DrawSingleTile
  mov {sprite_v,x}, draw_v
  mov {sprite_tile,x}, draw_tile
  mov {sprite_attr,x}, draw_attr
  mov {sprite_h,x}, draw_h
  rts
.endproc
