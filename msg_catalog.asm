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
.exportzp MSG_WARNING
.exportzp MSG_BOSS_FLY_IS_APPROACHING
.exportzp MSG_RESOLVE_YOUR_BATTLE
.exportzp MSG_YOU_DID_IT
.exportzp MSG_THE_KITCHEN_IS_CLEAN
.exportzp MSG_SELECT_LEVEL
.exportzp MSG_COPYRIGHT


.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "render_action.h.asm"

.importzp values
.importzp pointer


.segment "BOOT" ; should be in "CODE", but need to save space


msg_addr_high = msg_catalog
msg_addr_low = msg_catalog + 1
msg_length = msg_catalog + 2
msg_body = msg_catalog + 3

count = values + $00



; X @in  Identifier for the message.
.proc MsgRender
  lda msg_catalog+0,x
  sta pointer+0
  lda msg_catalog+1,x
  sta pointer+1
  ldy #2
  lda (pointer),y
  sta count
  jsr AllocateRenderAction
  tya
  tax
  ldy #0
  mov {render_action_addr_high,x}, {(pointer),y}
  iny
  mov {render_action_addr_low,x},  {(pointer),y}
  iny
  iny
Loop:
  lda (pointer),y
  sta render_action_data,x
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


.macro decl_msg identifier, location
  identifier = <( * - msg_catalog )
  .word location
.endmacro


msg_catalog:

decl_msg MSG_HEALTH, msg_health
decl_msg MSG_LIVES,  msg_lives
decl_msg MSG_SCORE,  msg_score
decl_msg MSG_COMBO,  msg_combo
decl_msg MSG_ZERO_SCORE, msg_0000000
decl_msg MSG_ZERO_COMBO, msg_000
decl_msg MSG_PRESS,  msg_press
decl_msg MSG_START,  msg_start

decl_msg MSG_THE_KITCHEN_IS,  msg_the_kitchen_is_so_dirty
decl_msg MSG_FIND_THE_BROOM,  msg_find_the_broom
decl_msg MSG_AND_CLEAN_IT_UP, msg_and_clean_it_up

decl_msg MSG_KILL_ALL_THE_FLIES, msg_kill_all_the_flies
decl_msg MSG_WATCH_OUT_FOR,      msg_watch_out_for_utensils
decl_msg MSG_AND_APPLIANCES,     msg_and_appliances

decl_msg MSG_KEEP_GOING_ALMOST, msg_keep_going_almost_there
decl_msg MSG_GET_COMBO_KILLS,   msg_get_combo_kills
decl_msg MSG_TO_EARN_HIGH,      msg_to_earn_high_scores

decl_msg MSG_WARNING,                 msg_warning
decl_msg MSG_BOSS_FLY_IS_APPROACHING, msg_boss_fly_is_approaching
decl_msg MSG_RESOLVE_YOUR_BATTLE,     msg_resolve_your_battle

decl_msg MSG_YOU_DID_IT,           msg_you_did_it
decl_msg MSG_THE_KITCHEN_IS_CLEAN, msg_the_kitchen_is_clean

decl_msg MSG_SELECT_LEVEL, msg_select_level
decl_msg MSG_COPYRIGHT,    msg_copyright


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

msg_warning:
MsgPosition 12, 12
.byte 7,"WARNING"

msg_boss_fly_is_approaching:
MsgPosition 14, 4
.byte 23,"BOSS FLY IS APPROACHING"

msg_resolve_your_battle:
MsgPosition 16, 6
.byte 19,"RESOLVE YOUR BATTLE"

msg_you_did_it:
MsgPosition 13, 10
.byte 11,"YOU DID IT!"

msg_the_kitchen_is_clean:
MsgPosition 15, 5
.byte 21,"THE KITCHEN IS CLEAN!"

msg_select_level:
MsgPosition 19, 13
.byte 5,"LEVEL"

msg_copyright:
MsgPosition 24, 9
.byte 14, "DUSTMOP # 2016"
