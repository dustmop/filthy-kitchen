.export MaybeDebugToggle

.include "include.mov-macros.asm"
.include "include.controller.asm"
.include "render_action.h.asm"

.importzp buttons_press, debug_mode

.segment "CODE"

.proc MaybeDebugToggle
  lda buttons_press
  and #BUTTON_SELECT
  beq Return
  lda debug_mode
  eor #$ff
  sta debug_mode
  beq DebugDisabled
DebugEnabled:
  lda #1
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$3f
  mov {render_action_addr_low,y}, #$00
  mov {render_action_data,y}, #$30
  jmp Return
DebugDisabled:
  lda #1
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$3f
  mov {render_action_addr_low,y}, #$00
  mov {render_action_data,y}, #$0f
Return:
  rts
.endproc
