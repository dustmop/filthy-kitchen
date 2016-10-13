.export PlayerInit
.export PlayerUpdate
.export PlayerDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.controller.asm"
.include "include.sprites.asm"
.include "detect_collision.h.asm"
.include "object_list.h.asm"

.importzp player_v, player_h, player_h_low, player_on_ground, player_screen
.importzp player_jump, player_jump_low, player_render_h, player_render_v
.importzp buttons, buttons_press
.importzp values

SWATTER_TILE = $02
PLAYER_TILE = $16
PLAYER_TILE_BOTTOM = $1a
SPEED_LOW  = $60
SPEED_HIGH = $01

START_V = $a8
START_H = $10

draw_v       = values + $00
draw_h       = values + $01
draw_tile    = values + $02
draw_attr    = values + $03
is_on_ground = values + $04


.segment "CODE"


.proc PlayerInit
  mov player_v, #START_V
  mov player_h, #START_H
  mov player_jump, #$00
  rts
.endproc


.proc PlayerUpdate

.scope CheckGround
  bit player_jump
  bmi NotOnGround
  lda player_screen
  ldx player_h
  ldy player_v
  jsr DetectCollisionWithBackground
  bcs IsOnGround
NotOnGround:
  mov is_on_ground, #$ff
  jmp Next
IsOnGround:
  sta player_v
  mov is_on_ground, #$00
  mov player_jump, #$00
Next:
.endscope

.scope HandleJump
  lda buttons_press
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

.scope HandleThrow
  lda buttons_press
  ; TODO: Only throw if the swatter is being held by the player.
  and #BUTTON_B
  beq Next
  jsr ObjectAllocate
  mov {object_kind,x}, #OBJECT_KIND_SWATTER
  mov {object_pos_h,x}, player_h
  mov {object_pos_v,x}, player_v
  ; TODO: Left or right direction.
  mov {object_dir,x}, #0
  mov {object_frame,x}, #0
  mov {object_step,x}, _
Next:
.endscope

.scope Gravity
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
  lda player_screen
  sbc #0
  sta player_screen
  jmp Next
MoveRight:
  lda player_h_low
  clc
  adc #SPEED_LOW
  sta player_h_low
  lda player_h
  adc #SPEED_HIGH
  sta player_h
  lda player_screen
  adc #0
  sta player_screen
Next:
.endscope

  rts
.endproc


.proc PlayerDraw
  ldx #$00

  mov draw_tile, #(SWATTER_TILE + 1)
  mov draw_attr, #0

  ; Swatter
  lda player_render_v
  clc
  adc #8
  sta draw_v
  lda player_render_h
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
  mov draw_v, player_render_v
  dec draw_v
  mov draw_h, player_render_h
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
  mov draw_h, player_render_h
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
