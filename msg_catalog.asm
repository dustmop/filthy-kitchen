.export MsgRender
.exportzp MSG_HEALTH, MSG_LIVES, MSG_SCORE, MSG_COMBO
.exportzp MSG_ZERO_SCORE, MSG_ZERO_COMBO, MSG_PRESS, MSG_START
.exportzp MSG_THE_KITCHEN_IS_FILTHY
.exportzp MSG_FIND_THE_BROOM

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "render_action.h.asm"

.importzp values


msg_addr_high = msg_catalog
msg_addr_low = msg_catalog + 1
msg_length = msg_catalog + 2
msg_body = msg_catalog + 3

count = values + $00


MSG_HEALTH     = <(msg_health - msg_catalog)
MSG_LIVES      = <(msg_lives - msg_catalog)
MSG_SCORE      = <(msg_score - msg_catalog)
MSG_COMBO      = <(msg_combo - msg_catalog)
MSG_ZERO_SCORE = <(msg_0000000 - msg_catalog)
MSG_ZERO_COMBO = <(msg_000 - msg_catalog)
MSG_PRESS      = <(msg_press - msg_catalog)
MSG_START      = <(msg_start - msg_catalog)

MSG_THE_KITCHEN_IS_FILTHY = <( msg_the_kitchen_is_filthy - msg_catalog )
MSG_FIND_THE_BROOM        = <( msg_find_the_broom - msg_catalog )


; X @in  Identifier for the message.
.proc MsgRender
  lda msg_length,x
  sta count
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, {msg_addr_high,x}
  mov {render_action_addr_low,y}, {msg_addr_low,x}
Loop:
  lda msg_body,x
  sta render_action_data,y
  iny
  inx
  dec count
  bne Loop
  rts
.endproc


.macro MsgPosition ypos, xpos
  .local high, low
high = ypos / 8 + $20
low = (ypos .mod 8) * $20 + xpos
  .byte high, low
.endmacro


msg_catalog:
.include ".b/hud_msg.asm"
.include ".b/title_msg.asm"

msg_the_kitchen_is_filthy:
MsgPosition 13, 5
.byte 22,"THE KITCHEN IS FILTHY!"

msg_find_the_broom:
MsgPosition 15, 9
.byte 14,"FIND THE BROOM"
