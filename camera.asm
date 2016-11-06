.export CameraInit
.export CameraUpdate

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "level_data.h.asm"

.importzp camera_h, camera_screen, player_h, player_v
.importzp player_screen, player_render_h, player_render_v
.importzp bg_x_scroll, bg_nt_select
.importzp level_max_camera_screen
.importzp level_max_camera_h
.importzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.importzp values

FILL_MOVING_RIGHT = 9
FILL_MOVING_LEFT  = $fe

orig_h             = values + $00
orig_scroll_action = values + $01
level_bit          = values + $02
tmp                = values + $03
lookahead          = values + $04


.segment "CODE"


.proc CameraInit
  mov camera_h, #0
  mov camera_screen, _
  mov level_max_camera_screen, #3
  mov level_max_camera_h, #0
  rts
.endproc


.proc CameraUpdate
  mov orig_h, camera_h
  and #$0e
  sta orig_scroll_action

  ; Determine camera position based upon where the player is.
  lda player_screen
  bne CalcOffset
  lda player_h
  cmp #$80
  bge CalcOffset

ZeroOffset:
  mov camera_h, #0
  mov camera_screen, _
  jmp GotOffset
CalcOffset:
  lda player_h
  sec
  sbc #$80
  sta camera_h
  lda player_screen
  sbc #0
  sta camera_screen

  cmp level_max_camera_screen
  blt GotOffset
  beq :+
  bge Overflow
:
  lda camera_h
  cmp level_max_camera_h
  blt GotOffset
Overflow:
  mov camera_h, level_max_camera_h
  mov camera_screen, level_max_camera_screen

GotOffset:

  ; Figure out if there's a rendering action to perform due to scrolling.
.scope ScrollAction
  lda camera_h
  cmp orig_h
  beq Next
  blt MovingLeft

MovingRight:
  mov lookahead, #FILL_MOVING_RIGHT
  jmp GotMoving
MovingLeft:
  mov lookahead, #FILL_MOVING_LEFT
GotMoving:

  ; Low bits of camera position determine the scroll action.
  lda camera_h
  and #$0e
  ; If the same as last frame, do nothing.
  cmp orig_scroll_action
  beq Next
  ; If outside of the action range, do nothing.
  cmp #SCROLL_ACTION_LIMIT
  bge Next
  ; Found an action that needs to be performed.
  sta NMI_SCROLL_action

  ; High bit of the level position.
  mov level_bit, #0
  lda camera_screen
  .repeat 3
  asl a
  .endrepeat
  and #$f0
  sta level_bit

  ; Get whether nametable is even or odd. Use that bit to figure out the target.
  lda camera_screen
  lsr a
  lda camera_h
  ror a
  .repeat 4
  lsr a
  .endrepeat
  clc
  adc lookahead
  sta NMI_SCROLL_target

  ; Target is only applicable to a position in the nametable. The level position
  ; can be larger than that. OR the level bit and lookup the strip id.
  clc
  adc level_bit
  jsr LevelDataGetStripId
  sta NMI_SCROLL_strip_id

Next:
.endscope

  ; Camera assigned to system's background scroll.
  lda camera_h
  sta bg_x_scroll

  ; Camera's high byte assigned to nametable select.
  lda camera_screen
  and #$03
  sta bg_nt_select

  ; Render player based upon their position and the camera.
  lda player_h
  sec
  sbc camera_h
  sta player_render_h

  mov player_render_v, player_v

Done:
  rts
.endproc
