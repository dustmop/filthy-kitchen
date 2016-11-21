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
.include "collision_data.h.asm"
.include "swatter.h.asm"
.include ".b/pictures.h.asm"

.importzp player_v, player_h, player_h_low, player_on_ground, player_screen
.importzp player_gravity, player_gravity_low, player_render_h, player_render_v
.importzp player_dir, player_owns_swatter, player_state, player_collision_idx
.importzp player_animate
.importzp buttons, buttons_press
.importzp level_max_h, level_max_screen
.importzp draw_screen
.importzp values

SWATTER_TILE = $02
PLAYER_TILE = $16
PLAYER_TILE_BOTTOM = $1a
SPEED_LOW  = $60
SPEED_HIGH = $01

START_V = $a8
START_H = $10

PLAYER_STATE_STANDING = 0
PLAYER_STATE_DUCKING  = 1
PLAYER_STATE_IN_AIR   = 2
PLAYER_STATE_WALKING  = 8

;DrawPicture   values + $00
draw_tile    = values + $01
draw_attr    = values + $02
is_on_ground = values + $03
tmp          = values + $04


.segment "CODE"


.proc PlayerInit
  mov player_v, #START_V
  mov player_h, #START_H
  mov player_dir, #$00
  mov player_gravity, _
  mov player_owns_swatter, #$ff
  ; Level data
  mov level_max_screen, #3
  mov level_max_h, #$ef
  rts
.endproc


.proc PlayerUpdate
  ; Apply gravity to v, for both jumping and falling.
.scope Gravity
  lda player_gravity
  clc
  adc player_v
  sta player_v
  inc player_gravity_low
  lda player_gravity_low
  cmp #5
  blt Next
  mov player_gravity_low, #0
  inc player_gravity
Next:
.endscope
  ; Check player against collision being below their feet.
.scope CheckGround
  bit player_gravity
  bmi NotOnGround
  lda player_screen
  ldx player_h
  ldy player_v
  jsr DetectCollisionWithBackground
  bcs IsOnGround
NotOnGround:
  mov is_on_ground, #$ff
  jmp AfterGroundMovement
IsOnGround:
  sta player_v
  mov is_on_ground, #$00
  mov player_gravity, #$00
Next:
.endscope
  ; Check if down is being pressed. If so, duck.
.scope HandleDuck
  lda buttons
  and #BUTTON_DOWN
  beq Standing
MaybeJump:
  bit is_on_ground
  bmi Standing
Ducking:
  mov player_state, #PLAYER_STATE_DUCKING
  mov player_collision_idx, #COLLISION_DATA_PLAYER_DUCKING
  jmp Next
Standing:
  mov player_state, #PLAYER_STATE_STANDING
  mov player_collision_idx, #COLLISION_DATA_PLAYER_STANDING
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
  mov player_gravity, #$fc
  mov player_gravity_low, #0
Next:
.endscope

AfterGroundMovement:
  ; Check if B is being pressed. If so, throw a swatter.
.scope HandleThrow
  lda buttons_press
  and #BUTTON_B
  beq Next
  ; Only throw if the swatter is being held by the player.
  lda player_owns_swatter
  bpl Next
  ; Success. Allocate and construct the object.
  jsr ObjectAllocate
  bcs Next
  stx player_owns_swatter
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_SWATTER
  mov {object_screen,x}, player_screen
  mov {object_life,x}, #$ff
  ; Spawn to the left or right of player.
  bit player_dir
  bpl SpawnToTheRight
SpawnToTheLeft:
  lda player_h
  sec
  sbc #$0c
  sta object_h,x
  lda object_screen,x
  sbc #0
  sta object_screen,x
  jmp SetVerticalPos
SpawnToTheRight:
  lda player_h
  clc
  adc #$0c
  sta object_h,x
  lda object_screen,x
  adc #0
  sta object_screen,x
SetVerticalPos:
  lda player_v
  clc
  adc #$08
  sta object_v,x
Speed:
  bit player_dir
  bpl FacingRight
FacingLeft:
  lda #($100 - SWATTER_MAX_SPEED)
  jmp HaveSpeed
FacingRight:
  lda #SWATTER_MAX_SPEED
HaveSpeed:
  sta swatter_speed,x
Next:
.endscope

  ; Check if Left or Right is being pressed.
.scope MaybeLeftOrRight
  lda player_state
  cmp #PLAYER_STATE_DUCKING
  beq NotWalking
  lda buttons
  and #BUTTON_LEFT
  bne MoveLeft
  lda buttons
  and #BUTTON_RIGHT
  bne MoveRight
  beq NotWalking
MoveLeft:
  mov player_state, #PLAYER_STATE_WALKING
  mov player_dir, #$ff
  inc player_animate
  lda player_animate
  and #$1f
  bne :+
  clc
  adc #1
:
  sta player_animate
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
  mov player_state, #PLAYER_STATE_WALKING
  mov player_dir, #0
  inc player_animate
  lda player_animate
  and #$1f
  sta player_animate
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
  jmp Next
NotWalking:
  mov player_animate, #0
Next:
.endscope

  ; Modify player state if the player is not on the ground.
.scope PlayerInAir
  bit is_on_ground
  bpl Next
  mov player_state, #PLAYER_STATE_IN_AIR
  mov player_animate, #0
Next:
.endscope

  rts
.endproc


.proc PlayerDraw
  mov draw_attr, #0
  mov draw_screen, _

  mov tmp, player_dir
  lda player_animate
  .repeat 3
  lsr a
  .endrepeat
  clc
  adc player_state
  asl tmp
  rol a
  pha
  tay

.scope SwatterDraw
  lda player_owns_swatter
  bpl Next
  ; Ensure that the swatter is drawn above the player by using indexes 4 and 8.
  ldx #$08
  jsr SpriteSpaceEnsure
  ldx #$04
  jsr SpriteSpaceEnsure

  mov draw_palette, #0
  MovWord draw_picture_pointer, swatter_picture_data
  MovWord draw_sprite_pointer, swatter_sprite_data

  lda swatter_animation_id,y
  sta draw_picture_id

  lda swatter_animation_h,y
  clc
  adc player_render_h
  sta draw_h

  lda swatter_animation_v,y
  clc
  adc player_render_v
  sta draw_v

  jsr DrawPicture
Next:
.endscope

  pla
  tay

  ; Player
  lda player_render_v
  sta draw_v
  lda player_render_h
  sta draw_h
  lda player_animation_id,y
  sta draw_picture_id
  mov draw_palette, #1
  MovWord draw_picture_pointer, player_picture_data
  MovWord draw_sprite_pointer, player_sprite_data
  jsr DrawPicture

  rts
.endproc


player_animation_id:
; PLAYER_STATE_STANDING
.byte PICTURE_ID_PLAYER_STAND_RIGHT, PICTURE_ID_PLAYER_STAND_LEFT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_PLAYER_DUCK_RIGHT, PICTURE_ID_PLAYER_DUCK_LEFT
; PLAYER_STATE_IN_AIR, TODO
.byte PICTURE_ID_PLAYER_STAND_RIGHT, PICTURE_ID_PLAYER_STAND_LEFT
; padding
.byte 0, 0
.byte 0, 0
.byte 0, 0
.byte 0, 0
.byte 0, 0
; PLAYER_STATE_WALKING
.byte PICTURE_ID_PLAYER_WALK0_RIGHT, PICTURE_ID_PLAYER_WALK0_LEFT
.byte PICTURE_ID_PLAYER_WALK1_RIGHT, PICTURE_ID_PLAYER_WALK1_LEFT
.byte PICTURE_ID_PLAYER_WALK0_RIGHT, PICTURE_ID_PLAYER_WALK0_LEFT
.byte PICTURE_ID_PLAYER_WALK2_RIGHT, PICTURE_ID_PLAYER_WALK2_LEFT

swatter_animation_id:
; PLAYER_STATE_STANDING
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
; PLAYER_STATE_IN_AIR, TODO
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
; padding
.byte 0, 0
.byte 0, 0
.byte 0, 0
.byte 0, 0
.byte 0, 0
; PLAYER_STATE_WALKING
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
.byte PICTURE_ID_SWATTER_RIGHT,    PICTURE_ID_SWATTER_LEFT
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
.byte PICTURE_ID_SWATTER_UP,       PICTURE_ID_SWATTER_UP

swatter_animation_h:
; PLAYER_STATE_STANDING
.byte  5, $fb
; PLAYER_STATE_DUCKING
.byte 14, $f2
; PLAYER_STATE_IN_AIR
.byte  5, $fb
; padding
.byte  0, 0
.byte  0, 0
.byte  0, 0
.byte  0, 0
.byte  0, 0
; PLAYER_STATE_WALKING
.byte  5, $fb
.byte  1, $ff
.byte  5, $fb
.byte  6, $fa

swatter_animation_v:
; PLAYER_STATE_STANDING
.byte  9, 9
; PLAYER_STATE_DUCKING
.byte 10, 10
; PLAYER_STATE_IN_AIR
.byte  9, 9
; padding
.byte  0, 0
.byte  0, 0
.byte  0, 0
.byte  0, 0
.byte  0, 0
; PLAYER_STATE_WALKING
.byte  9, 9
.byte 16, 16
.byte  9, 9
.byte  4, 4
