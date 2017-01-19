.export CameraInit
.export CameraUpdate

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "level_data.h.asm"

.importzp camera_h, camera_screen, player_h, player_v
.importzp player_screen, player_render_h, player_render_v
.importzp bg_x_scroll, bg_nt_select
.importzp level_max_screen
.importzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.importzp values

FILL_MOVING_RIGHT = 9
FILL_MOVING_LEFT  = $fe

orig_h             = values + $00
orig_scroll_action = values + $01
level_bit          = values + $02
tmp                = values + $03
lookahead          = values + $04
action_num         = values + $05


.segment "CODE"


.proc CameraInit
  mov camera_h, #0
  mov camera_screen, _
  rts
.endproc


.proc CameraUpdate
  mov orig_h, camera_h
  ; Action is determined by bits 1..3 of the camera position.
  and #$0e
  lsr a
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
  ; Set camera position so it is looking at the player.
  lda player_h
  sec
  sbc #$80
  sta camera_h
  lda player_screen
  sbc #0
  sta camera_screen

  ; Check for the end of the camera's view.
  cmp level_max_screen
  blt GotOffset
Overflow:
  mov camera_h, #0
  mov camera_screen, level_max_screen

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
  lsr a
  ; If the same as last frame, do nothing.
  cmp orig_scroll_action
  beq Next
  ; If outside of the action range, do nothing.
  cmp #SCROLL_ACTION_LIMIT
  bge Next
  ; Found an action that needs to be performed.
  sta action_num

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

  ; Get the strip_id.
  clc
  adc level_bit
  tay
  ldx action_num
  stx NMI_SCROLL_action
  jsr LevelDataGetStripId
  sty NMI_SCROLL_strip_id

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
