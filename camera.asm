.export CameraInit
.export CameraUpdate

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"

.importzp camera_h, camera_nt, player_h, player_v
.importzp player_screen, player_render_h, player_render_v
.importzp bg_x_scroll, ppu_ctrl_current
.importzp values

delta_h = values + $00


.segment "CODE"


.proc CameraInit
  mov camera_h, #0
  rts
.endproc


.proc CameraUpdate
  ; Determine camera position based upon where the player is.
  lda player_screen
  bne CalcOffset
  lda player_h
  cmp #$80
  bge CalcOffset
ZeroOffset:
  mov camera_h, #0
  mov camera_nt, _
  jmp GotOffset
CalcOffset:
  lda player_h
  sec
  sbc #$80
  sta camera_h
  lda player_screen
  sbc #0
  and #$03
  sta camera_nt
GotOffset:

  ; Camera assigned to system's background scroll.
  lda camera_h
  sta bg_x_scroll

  ; Camera's high byte assigned to nametable select.
  lda ppu_ctrl_current
  and #$fc
  ora camera_nt
  sta ppu_ctrl_current

  ; Render player based upon their position and the camera.
  lda player_h
  sec
  sbc camera_h
  sta player_render_h

  mov player_render_v, player_v

Done:
  rts
.endproc
