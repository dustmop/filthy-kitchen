.export PlayerInit
.export PlayerUpdate
.export PlayerDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.controller.asm"
.include "include.sprites.asm"
.include "detect_collision.h.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "draw_picture.h.asm"

.importzp player_v, player_h, player_h_low, player_on_ground, player_screen
.importzp player_jump, player_jump_low, player_render_h, player_render_v
.importzp buttons, buttons_press
.importzp level_max_h, level_max_screen
.importzp values

SWATTER_TILE = $02
PLAYER_TILE = $16
PLAYER_TILE_BOTTOM = $1a
SPEED_LOW  = $60
SPEED_HIGH = $01

START_V = $a8
START_H = $10

;DrawPicture   values + $00
draw_tile    = values + $01
draw_attr    = values + $02
is_on_ground = values + $03


.segment "CODE"


.proc PlayerInit
  mov player_v, #START_V
  mov player_h, #START_H
  mov player_jump, #$00
  ; Level data
  mov level_max_screen, #3
  mov level_max_h, #$ef
  rts
.endproc


.proc PlayerUpdate

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
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_SWATTER
  lda player_h
  clc
  adc #$0c
  sta object_pos_h,x
  lda player_v
  clc
  adc #$08
  sta object_pos_v,x
  ; TODO: Left or right direction.
  mov {object_dir,x}, #0
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
  bpl MoveLeftOkay
  ; Underflow
  lda #0
  sta player_h
  sta player_screen
MoveLeftOkay:
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
  cmp level_max_screen
  blt Next
  lda level_max_screen
  sta player_screen
  lda player_h
  cmp level_max_h
  blt Next
  lda level_max_h
  sta player_h
Next:
.endscope

  rts
.endproc


.proc PlayerDraw
  mov draw_attr, #0

  ; Ensure that the swatter is drawn above the player by using indexes 4 and 8.
  ldx #$08
  jsr SpriteSpaceEnsure
  ldx #$04
  jsr SpriteSpaceEnsure

  ; Swatter
  lda player_render_v
  clc
  adc #8
  sta draw_v
  lda player_render_h
  clc
  adc #6
  sta draw_h
  mov draw_picture_id, #3
  mov draw_palette, #0
  MovWord draw_picture_pointer, swatter_picture_data
  MovWord draw_sprite_pointer, swatter_sprite_data
  jsr DrawPicture

  ; Player
  lda player_render_v
  sta draw_v
  lda player_render_h
  sta draw_h
  mov draw_picture_id, #0
  mov draw_palette, #1
  MovWord draw_picture_pointer, player_picture_data
  MovWord draw_sprite_pointer, player_sprite_data
  jsr DrawPicture

  rts
.endproc
