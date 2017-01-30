.import AllocateRenderAction
.import RenderActionApplyAll
.import RenderActionClear

render_action_size      = $700
render_action_addr_high = $701
render_action_addr_low  = $702
render_action_data      = $703

render_action_buffer    = $700

.macro RenderActionSetYX ypos, xpos
  lda #($20 + (ypos / 8))
  sta render_action_addr_high,y
  lda #(xpos + (ypos .mod 8) * $20)
  sta render_action_addr_low,y
.endmacro
