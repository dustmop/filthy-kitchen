.export PlayerInit
.export PlayerUpdate
.export PlayerDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.controller.asm"
.include "include.sprites.asm"
.include "include.const.asm"
.include "detect_collision.h.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "draw_picture.h.asm"

.importzp player_v, player_h, player_h_low, player_on_ground, player_screen
.importzp player_jump, player_jump_low, player_render_h, player_render_v
.importzp player_dir
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
  mov player_dir, #$00
  mov player_jump, _
  ; Level data
  mov level_max_screen, #3
  mov level_max_h, #$ef
  rts
.endproc


.proc PlayerUpdate
  ; Apply gravity to v, for both jumping and falling.
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
  ; Check player against collision being below their feet.
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
  ; Check if A is being pressed. If so, start a jump.
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
  ; Check if B is being pressed. If so, throw a swatter.
.scope HandleThrow
  lda buttons_press
  ; TODO: Only throw if the swatter is being held by the player.
  and #BUTTON_B
  beq Next
  jsr ObjectAllocate
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_SWATTER
  mov {object_h_screen,x}, player_screen
  mov {object_life,x}, #$ff
  ; Spawn to the left or right of player.
  bit player_dir
  bpl SpawnToTheRight
SpawnToTheLeft:
  lda player_h
  sec
  sbc #$0c
  sta object_h,x
  jmp SetVerticalPos
SpawnToTheRight:
  lda player_h
  clc
  adc #$0c
  sta object_h,x
SetVerticalPos:
  lda player_v
  clc
  adc #$08
  sta object_v,x
Speed:
  bit player_dir
  bpl FacingRight
FacingLeft:
  lda #($100 - SWATTER_SPEED)
  jmp HaveSpeed
FacingRight:
  lda #SWATTER_SPEED
HaveSpeed:
  sta object_speed,x
Next:
.endscope
  ; Check if Left or Right is being pressed.
.scope MaybeLeftOrRight
  lda buttons
  and #BUTTON_LEFT
  bne MoveLeft
  lda buttons
  and #BUTTON_RIGHT
  bne MoveRight
  beq Next
MoveLeft:
  mov player_dir, #$ff
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
  mov player_dir, #0
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
  ; Overflow
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

.scope SwatterDraw
  ; Ensure that the swatter is drawn above the player by using indexes 4 and 8.
  ldx #$08
  jsr SpriteSpaceEnsure
  ldx #$04
  jsr SpriteSpaceEnsure

  mov draw_palette, #0
  MovWord draw_picture_pointer, swatter_picture_data
  MovWord draw_sprite_pointer, swatter_sprite_data

  bit player_dir
  bmi FacingLeft
FacingRight:
  mov draw_picture_id, #3
  lda #$06
  bpl DrawIt
FacingLeft:
  mov draw_picture_id, #8
  lda #$0fc
DrawIt:
  clc
  adc player_render_h
  sta draw_h
  lda #$09
  clc
  adc player_render_v
  sta draw_v
  jsr DrawPicture
.endscope

  ; Player
  lda player_render_v
  sta draw_v
  lda player_render_h
  sta draw_h
  lda player_dir
  and #$06
  sta draw_picture_id
  mov draw_palette, #1
  MovWord draw_picture_pointer, player_picture_data
  MovWord draw_sprite_pointer, player_sprite_data
  jsr DrawPicture

  rts
.endproc
