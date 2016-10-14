.export LevelDataGetStripId, LevelDataFillEntireScreen, LevelDataUpdateScroll

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sys.asm"

.importzp ppu_ctrl_current
.importzp NMI_pointer
.importzp NMI_values
.importzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.import collision_map

FILL_LOOKAHEAD = 9

pointer = NMI_pointer
values = NMI_values

strip_id   = values + $00
target     = values + $01
offset     = values + $02
upper_addr = values + $03
high_byte  = values + $04

; DEBUGGING ONLY
debug_10_action   = $410
debug_11_offset   = $411
debug_12_target   = $412
debug_13_strip_id = $413


.segment "CODE"


.proc LevelDataGetStripId
  tax
  lda level_data,x
  rts
.endproc


.proc LevelDataFillEntireScreen
  jsr PrepareRender
  ldx #0
Loop:
  jsr FillFullStrip
  inx
  cpx #FILL_LOOKAHEAD
  bne Loop
  rts
.endproc


.proc LevelDataUpdateScroll
  lda NMI_SCROLL_action
  beq Return

  sta debug_10_action

  cmp #SCROLL_ACTION_ATTR
  beq UpdateAttribute
  cmp #SCROLL_ACTION_COLLISION
  beq UpdateCollision
  cmp #SCROLL_ACTION_LIMIT
  bge Acknowledge

UpdateNametable:
  ;
  sec
  sbc #2
  lsr a
  sta offset
  sta debug_11_offset
  ;
  mov target, NMI_SCROLL_target
  sta debug_12_target
  mov strip_id, NMI_SCROLL_strip_id
  sta debug_13_strip_id
  ;
  jsr PrepareRender
  jsr RenderNametableSingleSubstrip
  jmp Acknowledge
UpdateAttribute:
  mov target, NMI_SCROLL_target
  sta debug_12_target
  mov strip_id, NMI_SCROLL_strip_id
  sta debug_13_strip_id
  jsr RenderAttribute
  jmp Acknowledge
UpdateCollision:
  mov target, NMI_SCROLL_target
  sta debug_12_target
  mov strip_id, NMI_SCROLL_strip_id
  sta debug_13_strip_id
  jsr FillCollision

Acknowledge:
  ; Acknowledge action.
  mov NMI_SCROLL_action, #0

Return:
  rts
.endproc


.proc FillFullStrip
  stx target
  mov strip_id, {level_data,x}
  txa
  pha
  jsr RenderNametableStrip
  jsr RenderAttribute
  jsr FillCollision
  pla
  tax
  rts
.endproc


.proc PrepareRender
  bit PPU_STATUS
  lda ppu_ctrl_current
  ora #PPU_CTRL_VRAM_INC_32
  sta ppu_ctrl_current
  sta PPU_CTRL
  rts
.endproc


.proc RenderNametableStrip
  ; Offset of the sub-strip to render, of which there are 4.
  mov offset, #0
Loop:
  jsr RenderNametableSingleSubstrip
  inc offset
  lda offset
  cmp #4
  bne Loop
  rts
.endproc


; Input:
;   offset   - Offset within the strip, 0..3
;   target   - Which strip in the nametable to render, 0..15
;   strip_id - Strip id to get level data from.
.proc RenderNametableSingleSubstrip
  mov high_byte, #0
  ; Set up pointer to nametable data.
  ; ((strip_id * 4) + offset) * (30[length] + 2[pad])
  lda strip_id
  .repeat 2
  asl a
  rol high_byte
  .endrepeat
  clc
  adc offset
  .repeat 5
  asl a
  rol high_byte
  .endrepeat
  clc
  adc #<level_nt_column
  sta pointer+0
  lda high_byte
  adc #>level_nt_column
  sta pointer+1

  ; Select which nametable to render to, $2000 or $2400.
  lda target
  and #$08
  lsr a
  clc
  adc #$20
  sta PPU_ADDR

  ; Y is the position in the strip, starting at the top.
  ldy #0
  lda target
  and #$07
  asl a
  asl a
  clc
  adc offset
  sta PPU_ADDR
  ; Render a sub-strip, 30 elements.
  ldx #$1e
RenderLoop:
  lda (pointer),y
  sta PPU_DATA
  iny
  dex
  bne RenderLoop

Return:
  rts
.endproc


.proc RenderAttribute
  ; Select which nametable to render attributes to, $23c0 or $27c0.
  lda target
  and #$08
  lsr a
  clc
  adc #$23
  sta upper_addr

  ; Set up pointer to attribute data. Treat high_byte:strip_id as 16-bit value.
  ; Units are 8 bytes.
  mov high_byte, #0
  lda strip_id
  .repeat 3
  asl a
  rol high_byte
  .endrepeat
  clc
  adc #<level_attribute
  sta pointer+0
  lda high_byte
  adc #>level_attribute
  sta pointer+1

  ; Starting position within this nametable.
  lda target
  and #$07
  clc
  adc #$c0
  tax
  ; Start at the top of the attributes, render 8 bytes.
  ldy #0
Loop:

  lda upper_addr
  sta PPU_ADDR
  stx PPU_ADDR

  lda (pointer),y
  sta PPU_DATA

  ; Move vertically by adding 8.
  txa
  clc
  adc #8
  tax

  iny
  cpy #$08
  bne Loop

  rts
.endproc


.proc FillCollision
  ; Set up pointer to collision data. Treat high_byte:strip_id as 16-bit value.
  ; Units are 15[bytes] + 1[pad] = 16.
  mov high_byte, #0
  lda strip_id
  .repeat 4
  asl a
  rol high_byte
  .endrepeat
  clc
  adc #<level_collision
  sta pointer+0
  lda high_byte
  adc #>level_collision
  sta pointer+1

  ; Poke into memory vertically.
  lda target
  and #$0f
  tax
  ldy #0
Loop:
  lda (pointer),y
  sta collision_map,x
  txa
  clc
  adc #$10
  tax
  iny
  cpy #$0f
  bne Loop

  rts
.endproc



level_data:
.incbin ".b/level_data.dat"

level_nt_column:
.incbin ".b/level_data_nt_column.dat"

level_attribute:
.incbin ".b/level_data_attribute.dat"

level_collision:
.incbin ".b/level_data_collision.dat"
