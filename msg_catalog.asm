.export MsgRender
.exportzp MSG_HEALTH, MSG_LIVES, MSG_SCORE, MSG_COMBO
.exportzp MSG_ZERO_SCORE, MSG_ZERO_COMBO, MSG_PRESS, MSG_START
.exportzp MSG_THE_KITCHEN_IS
.exportzp MSG_FIND_THE_BROOM
.exportzp MSG_AND_CLEAN_IT_UP
.exportzp MSG_KILL_ALL_THE_FLIES
.exportzp MSG_WATCH_OUT_FOR
.exportzp MSG_AND_APPLIANCES
.exportzp MSG_KEEP_GOING_ALMOST
.exportzp MSG_GET_COMBO_KILLS
.exportzp MSG_TO_EARN_HIGH


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

MSG_THE_KITCHEN_IS = <( msg_the_kitchen_is_so_dirty - msg_catalog )
MSG_FIND_THE_BROOM = <( msg_find_the_broom - msg_catalog )
MSG_AND_CLEAN_IT_UP = <( msg_and_clean_it_up - msg_catalog )

MSG_KILL_ALL_THE_FLIES = <( msg_kill_all_the_flies - msg_catalog )
MSG_WATCH_OUT_FOR      = <( msg_watch_out_for_utensils - msg_catalog )
MSG_AND_APPLIANCES     = <( msg_and_appliances - msg_catalog )

MSG_KEEP_GOING_ALMOST  = <( msg_keep_going_almost_there - msg_catalog )
MSG_GET_COMBO_KILLS    = <( msg_get_combo_kills - msg_catalog )
MSG_TO_EARN_HIGH       = <( msg_to_earn_high_scores - msg_catalog )


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

msg_the_kitchen_is_so_dirty:
MsgPosition 12, 4
.byte 24,"THE KITCHEN IS SO DIRTY!"

msg_find_the_broom:
MsgPosition 14, 9
.byte 14,"FIND THE BROOM"

msg_and_clean_it_up:
MsgPosition 16, 8
.byte 16,"AND CLEAN IT UP!"

msg_kill_all_the_flies:
MsgPosition 12, 7
.byte 19,"KILL ALL THE FLIES!"

msg_watch_out_for_utensils:
MsgPosition 14, 5
.byte 22,"WATCH OUT FOR UTENSILS"

msg_and_appliances:
MsgPosition 16, 9
.byte 14,"AND APPLIANCES"

msg_keep_going_almost_there:
MsgPosition 12, 4
.byte 23,"KEEP GOING ALMOST THERE"

msg_get_combo_kills:
MsgPosition 14, 8
.byte 15,"GET COMBO KILLS"

msg_to_earn_high_scores:
MsgPosition 16, 6
.byte 19,"TO EARN HIGH SCORES"
