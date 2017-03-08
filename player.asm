.export PlayerClearData
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
.include "flash.h.asm"
.include ".b/pictures.h.asm"
.include "famitone.h.asm"
.include "sound.h.asm"

.importzp player_v, player_h, player_h_low, player_on_ground, player_screen
.importzp player_gravity, player_gravity_low, player_render_h, player_render_v
.importzp player_dir, player_owns_swatter, player_state, player_collision_idx
.importzp player_animate, player_injury, player_iframe, player_throw
.importzp player_health, player_removed
.importzp buttons, buttons_press
.importzp level_max_screen
.importzp draw_screen
.importzp player_state_begin, player_state_end
.importzp level_player_start_v, level_has_entrance_door
.import swatter_speed, swatter_speed_low, swatter_v_low

.importzp values

SPEED_LOW_RIGHT    = $60
SPEED_HIGH_RIGHT   = $01
SPEED_SCREEN_RIGHT = $00
SPEED_LOW_LEFT     = $a0
SPEED_HIGH_LEFT    = $fe
SPEED_SCREEN_LEFT  = $ff

BOUNCE_LOW_RIGHT    = $c0
BOUNCE_HIGH_RIGHT   = $00
BOUNCE_SCREEN_RIGHT = $00
BOUNCE_LOW_LEFT     = $40
BOUNCE_HIGH_LEFT    = $ff
BOUNCE_SCREEN_LEFT  = $ff

START_H = $10

LEVEL_MAX_H = $ef

PLAYER_STATE_STANDING = 0
PLAYER_STATE_DUCKING  = 1
PLAYER_STATE_IN_AIR   = 2
PLAYER_STATE_HURT     = 4
PLAYER_STATE_DEAD     = 5
PLAYER_STATE_WALKING  = 8

THROW_START_TIME = 14
THROW_WAKEUP_FRAMES = 4

;DrawPicture   values + $00
draw_tile    = values + $01
draw_attr    = values + $02
is_on_ground = values + $07
tmp          = values + $08


.segment "CODE"


.proc PlayerClearData
  lda #0
  ldx #0
ClearLoop:
  sta player_state_begin,x
  inx
  cpx #(player_state_end - player_state_begin)
  bne ClearLoop
  rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc PlayerInit
  mov player_v, level_player_start_v
  mov player_h, #START_H
  mov player_screen, #0
  mov player_dir, #$00
  mov player_gravity, _
  mov player_owns_swatter, #$ff
  rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc PlayerUpdate
  ; If removed
.scope IfRemoved
  lda player_removed
  beq Next
  inc player_removed
  rts
Next:
.endscope
  ; If dead
.scope IfDead
  lda player_health
  bne Next
  mov player_state, #PLAYER_STATE_DEAD
  mov player_animate, #0
  ;
  jsr FamiToneMusicStop
Next:
.endscope
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
  ;
.scope RemoveIfDeadAndOffscreen
  lda player_health
  bne Next
  lda player_v
  cmp #$f0
  blt Next
  mov player_removed, #1
  rts
Next:
.endscope
  ; Check player against collision being below their feet.
.scope CheckGround
  lda player_health
  beq NotOnGround
  bit player_gravity
  bmi NotOnGround
  lda player_screen
  ldx player_h
  ldy player_v
  jsr DetectCollisionWithGround
  bcs IsOnGround
NotOnGround:
  mov is_on_ground, #$ff
  jmp Next
IsOnGround:
  sta player_v
  mov is_on_ground, #$00
  mov player_gravity, #$00
Next:
.endscope
  ; Check if injured.
.scope CheckInjured
  lda player_health
  beq MovePlayer
  lda player_injury
  beq Next
  dec player_injury
  mov player_state, #PLAYER_STATE_HURT
  mov player_animate, #0
  bit is_on_ground
  bpl Return
MovePlayer:
  bit player_dir
  bpl MoveLeft
MoveRight:
  lda #BOUNCE_LOW_RIGHT
  ldx #BOUNCE_HIGH_RIGHT
  ldy #BOUNCE_SCREEN_RIGHT
  beq InjuredMovement
MoveLeft:
  lda #BOUNCE_LOW_LEFT
  ldx #BOUNCE_HIGH_LEFT
  ldy #BOUNCE_SCREEN_LEFT
InjuredMovement:
  jsr MovePlayerSideways
Return:
  rts
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
  ; Play sound of jumping
  lda #SFX_JUMP
  jsr SoundPlay
Next:
.endscope

  ; No jmp comes to this label.
GroundMovement:

  ; B throws the swatter.
.scope HandleThrow
  lda player_throw
  beq MaybeBegin
  dec player_throw
  lda player_throw
  cmp #(THROW_START_TIME - THROW_WAKEUP_FRAMES)
  bne Next
  ; Throw the swatter finally.
  jsr SpawnSwatter
  jmp Next
MaybeBegin:
  ; Check if B is being pressed. If so, begin to throw the swatter.
  lda buttons_press
  and #BUTTON_B
  beq Next
  ; Only throw if the swatter is being held by the player.
  lda player_owns_swatter
  bpl Next
  ; Only throw if a throw has not already started.
  lda player_throw
  bne Next
  ; Success, begin throw.
  mov player_throw, #THROW_START_TIME
Next:
.endscope

  ; Check if Left or Right is being pressed.
.scope MaybeLeftOrRight
  lda player_state
  cmp #PLAYER_STATE_DUCKING
  beq NotWalking
  lda buttons
  and #BUTTON_LEFT
  bne MaybeMoveLeft
  lda buttons
  and #BUTTON_RIGHT
  bne MaybeMoveRight
  beq NotWalking
MaybeMoveLeft:
  lda player_screen
  ldx player_h
  ldy player_v
  jsr DetectCollisionWithWallLeft
  bcs NotWalking
MoveLeft:
  mov player_dir, #$ff
  lda #SPEED_LOW_LEFT
  ldx #SPEED_HIGH_LEFT
  ldy #SPEED_SCREEN_LEFT
  jsr MovePlayerSideways
  jmp AnimateWalking
MaybeMoveRight:
  lda player_screen
  ldx player_h
  ldy player_v
  jsr DetectCollisionWithWallRight
  bcs NotWalking
MoveRight:
  mov player_dir, #0
  lda #SPEED_LOW_RIGHT
  ldx #SPEED_HIGH_RIGHT
  ldy #SPEED_SCREEN_RIGHT
  jsr MovePlayerSideways
AnimateWalking:
  mov player_state, #PLAYER_STATE_WALKING
  inc player_animate
  lda player_animate
  and #$1f
  sta player_animate
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
  bit player_gravity
  bpl Falling
Jumping:
  lda #0
  skip2
Falling:
  lda #8
  sta player_animate
Next:
.endscope

  rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; A = speed_low
; X = speed_high
; Y = speed_screen
.proc MovePlayerSideways
  clc
  adc player_h_low
  sta player_h_low
  txa
  adc player_h
  sta player_h
  tya
  adc player_screen
  sta player_screen
  bmi Underflow
  cmp level_max_screen
  blt Return
  lda player_h
  cmp #LEVEL_MAX_H
  blt Return
Overflow:
  lda level_max_screen
  sta player_screen
  lda #LEVEL_MAX_H
  sta player_h
  rts
Underflow:
  lda #0
  sta player_h
  sta player_screen
Return:
  rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc PlayerDraw
  mov draw_attr, #0
  mov draw_screen, _

.scope Background
  bit level_has_entrance_door
  bpl Next
  lda player_screen
  bne Next
  lda player_h
  cmp #$d0
  blt Next
  cmp #$f8
  bge Next
  mov draw_attr, #$20
Next:
.endscope

.scope ThrowAddition
  lda player_throw
  beq Next
  ; Throw is happening.
  lda player_state
  cmp #PLAYER_STATE_WALKING
  bne PickFrame
  ; When walking, clear the animate step so that we draw the throw animation.
  mov player_animate, #0
PickFrame:
  lda player_throw
  cmp #(THROW_START_TIME - THROW_WAKEUP_FRAMES + 1)
  blt ThrowFrame1
ThrowFrame0:
  lda player_animate
  clc
  adc #(12 * 8)
  sta player_animate
  bpl Next
ThrowFrame1:
  lda player_animate
  clc
  adc #(24 * 8)
  sta player_animate
Next:
.endscope

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

  mov draw_palette, draw_attr
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

  jsr SpriteSpaceRelax
Next:
.endscope

  pla
  tay

.scope CheckVisibility
  lda player_health
  beq Visible
  lda player_iframe
  beq Visible
  dec player_iframe
  and #$0f
  tax
  lda flash_priority,x
  bne Visible
Hidden:
  rts
Visible:
.endscope

  ; Player
  lda player_render_v
  sta draw_v
  lda player_render_h
  sta draw_h
  lda player_animation_id,y
  sta draw_picture_id
  lda draw_attr
  ora #$1
  sta draw_palette
  MovWord draw_picture_pointer, player_picture_data
  MovWord draw_sprite_pointer, player_sprite_data
  jsr DrawPicture

  rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc SpawnSwatter
  ; Allocate and construct the object.
  jsr ObjectAllocate
  bcc Return
  stx player_owns_swatter
  jsr ObjectConstructor
  mov {object_kind,x}, #OBJECT_KIND_SWATTER
  mov {object_screen,x}, player_screen
  mov {swatter_speed,x}, #$0
  mov {swatter_speed_low,x}, _
  mov {swatter_v_low,x}, _
  ; Play sound
  lda #SFX_THROW_SWATTER
  jsr SoundPlay
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
Return:
  rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_animation_id:
; PLAYER_STATE_STANDING
.byte PICTURE_ID_PLAYER_STAND_RIGHT, PICTURE_ID_PLAYER_STAND_LEFT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_PLAYER_DUCK_RIGHT, PICTURE_ID_PLAYER_DUCK_LEFT
; PLAYER_STATE_IN_AIR
.byte PICTURE_ID_PLAYER_JUMP_RIGHT, PICTURE_ID_PLAYER_JUMP_LEFT
.byte PICTURE_ID_PLAYER_FALL_RIGHT, PICTURE_ID_PLAYER_FALL_LEFT
; PLAYER_STATE_HURT
.byte PICTURE_ID_PLAYER_HURT_RIGHT, PICTURE_ID_PLAYER_HURT_LEFT
; PLAYER_STATE_HURT
.byte PICTURE_ID_PLAYER_DEAD_RIGHT, PICTURE_ID_PLAYER_DEAD_LEFT
; padding
.byte 0, 0
.byte 0, 0
; PLAYER_STATE_WALKING
.byte PICTURE_ID_PLAYER_WALK0_RIGHT, PICTURE_ID_PLAYER_WALK0_LEFT
.byte PICTURE_ID_PLAYER_WALK1_RIGHT, PICTURE_ID_PLAYER_WALK1_LEFT
.byte PICTURE_ID_PLAYER_WALK0_RIGHT, PICTURE_ID_PLAYER_WALK0_LEFT
.byte PICTURE_ID_PLAYER_WALK2_RIGHT, PICTURE_ID_PLAYER_WALK2_LEFT

; THROWING_0_STANDING
.byte PICTURE_ID_THROW_0_STAND_RIGHT, PICTURE_ID_THROW_0_STAND_LEFT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_PLAYER_DUCK_RIGHT, PICTURE_ID_PLAYER_DUCK_LEFT;
; PLAYER_STATE_IN_AIR
.byte PICTURE_ID_PLAYER_JUMP_RIGHT, PICTURE_ID_PLAYER_JUMP_LEFT;
.byte PICTURE_ID_PLAYER_FALL_RIGHT, PICTURE_ID_PLAYER_FALL_LEFT;
; PLAYER_STATE_HURT
.byte PICTURE_ID_PLAYER_HURT_RIGHT, PICTURE_ID_PLAYER_HURT_LEFT;
; PLAYER_STATE_HURT
.byte PICTURE_ID_PLAYER_DEAD_RIGHT, PICTURE_ID_PLAYER_DEAD_LEFT;
; padding
.byte 0, 0
.byte 0, 0
; PLAYER_STATE_WALKING
.byte PICTURE_ID_THROW_0_WALK_RIGHT, PICTURE_ID_THROW_0_WALK_LEFT
.byte 0, 0
.byte 0, 0
.byte 0, 0

; THROWING_1_STANDING
.byte PICTURE_ID_THROW_1_STAND_RIGHT, PICTURE_ID_THROW_1_STAND_LEFT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_PLAYER_DUCK_RIGHT, PICTURE_ID_PLAYER_DUCK_LEFT;
; PLAYER_STATE_IN_AIR
.byte PICTURE_ID_PLAYER_JUMP_RIGHT, PICTURE_ID_PLAYER_JUMP_LEFT;
.byte PICTURE_ID_PLAYER_FALL_RIGHT, PICTURE_ID_PLAYER_FALL_LEFT;
; PLAYER_STATE_HURT
.byte PICTURE_ID_PLAYER_HURT_RIGHT, PICTURE_ID_PLAYER_HURT_LEFT;
; PLAYER_STATE_HURT
.byte PICTURE_ID_PLAYER_DEAD_RIGHT, PICTURE_ID_PLAYER_DEAD_LEFT;
; padding
.byte 0, 0
.byte 0, 0
; THROWING_1_WALKING
.byte PICTURE_ID_THROW_1_WALK_RIGHT, PICTURE_ID_THROW_1_WALK_LEFT;
.byte 0, 0
.byte 0, 0
.byte 0, 0


swatter_animation_id:
; PLAYER_STATE_STANDING
.byte PICTURE_ID_SWATTER_UP_RIGHT,   PICTURE_ID_SWATTER_UP_LEFT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_SWATTER_UP_RIGHT,   PICTURE_ID_SWATTER_UP_LEFT
; PLAYER_STATE_IN_AIR, TODO
.byte PICTURE_ID_SWATTER_DOWN_RIGHT, PICTURE_ID_SWATTER_DOWN_LEFT
.byte PICTURE_ID_SWATTER_UP,         PICTURE_ID_SWATTER_UP
; PLAYER_STATE_HURT
.byte PICTURE_ID_SWATTER_UP_LEFT, PICTURE_ID_SWATTER_UP_RIGHT
; PLAYER_STATE_HURT
.byte PICTURE_ID_SWATTER_UP_LEFT, PICTURE_ID_SWATTER_UP_RIGHT
; padding
.byte 0, 0
.byte 0, 0
; PLAYER_STATE_WALKING
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
.byte PICTURE_ID_SWATTER_RIGHT,    PICTURE_ID_SWATTER_LEFT
.byte PICTURE_ID_SWATTER_UP_RIGHT, PICTURE_ID_SWATTER_UP_LEFT
.byte PICTURE_ID_SWATTER_UP,       PICTURE_ID_SWATTER_UP

; PLAYER_STATE_STANDING
.byte PICTURE_ID_SWATTER_UP_LEFT,   PICTURE_ID_SWATTER_UP_RIGHT
; PLAYER_STATE_DUCKING
.byte PICTURE_ID_SWATTER_UP_RIGHT,   PICTURE_ID_SWATTER_UP_LEFT;
; PLAYER_STATE_IN_AIR, TODO
.byte PICTURE_ID_SWATTER_DOWN_RIGHT, PICTURE_ID_SWATTER_DOWN_LEFT;
.byte PICTURE_ID_SWATTER_UP,         PICTURE_ID_SWATTER_UP;
; PLAYER_STATE_HURT
.byte PICTURE_ID_SWATTER_UP_LEFT, PICTURE_ID_SWATTER_UP_RIGHT;
; PLAYER_STATE_HURT
.byte PICTURE_ID_SWATTER_UP_LEFT, PICTURE_ID_SWATTER_UP_RIGHT;
; padding
.byte 0, 0
.byte 0, 0
; PLAYER_STATE_WALKING
.byte PICTURE_ID_SWATTER_UP_LEFT,   PICTURE_ID_SWATTER_UP_RIGHT
.byte 0, 0
.byte 0, 0
.byte 0, 0


swatter_animation_h:
; PLAYER_STATE_STANDING
.byte   5, $fb
; PLAYER_STATE_DUCKING
.byte  14, $f2
; PLAYER_STATE_IN_AIR
.byte $ff, $01
.byte $fa, $06
; PLAYER_STATE_HURT
.byte $f3, $0e
; PLAYER_STATE_DEAD
.byte $f3, $0e
; padding
.byte   0, 0
.byte   0, 0
; PLAYER_STATE_WALKING
.byte   5, $fb
.byte   1, $ff
.byte   5, $fb
.byte   6, $fa

; PLAYER_STATE_STANDING
.byte  $f1, $0f
; PLAYER_STATE_DUCKING
.byte  14, $f2;
; PLAYER_STATE_IN_AIR
.byte $ff, $01;
.byte $fa, $06;
; PLAYER_STATE_HURT
.byte $f3, $0e;
; PLAYER_STATE_DEAD
.byte $f3, $0e;
; padding
.byte   0, 0;
.byte   0, 0;
; PLAYER_STATE_WALKING
.byte  $f1, $0f
.byte   0, 0;
.byte   0, 0;
.byte   0, 0;


swatter_animation_v:
; PLAYER_STATE_STANDING
.byte   9, 9
; PLAYER_STATE_DUCKING
.byte  10, 10
; PLAYER_STATE_IN_AIR
.byte $12, $12
.byte $f7, $f7
; PLAYER_STATE_HURT
.byte   8, 8
; PLAYER_STATE_DEAD
.byte   8, 8
; padding
.byte   0, 0
.byte   0, 0
; PLAYER_STATE_WALKING
.byte   9, 9
.byte  16, 16
.byte   9, 9
.byte   4, 4

; PLAYER_STATE_STANDING
.byte   5, 5
; PLAYER_STATE_DUCKING
.byte  10, 10;
; PLAYER_STATE_IN_AIR
.byte $12, $12;
.byte $f7, $f7;
; PLAYER_STATE_HURT
.byte   8, 8;
; PLAYER_STATE_DEAD
.byte   8, 8;
; padding
.byte   0, 0
.byte   0, 0
; PLAYER_STATE_WALKING
.byte   5, 5
.byte   0, 0
.byte   0, 0
.byte   0, 0
