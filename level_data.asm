.export LevelClearData
.export LevelDataGetStripId, LevelDataFillEntireScreen, LevelDataUpdateScroll

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sys.asm"
.include "gfx.h.asm"

.importzp ppu_ctrl_current
.importzp NMI_pointer
.importzp NMI_values
.importzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.importzp level_state_begin, level_state_end
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


.proc LevelClearData
  lda #0
  ldx #0
ClearLoop:
  sta level_state_begin,x
  inx
  cpx #(level_state_end - level_state_begin)
  bne ClearLoop
  rts
.endproc


; input X: Distance into the level data.
; input Y: Action kind, 1..4 for nt, 5 for attr, 6 for collision
; output X: Strip id
.proc LevelDataGetStripId
chunk_id = strip_id
  ; Get chunk_id.
  lda level_data,x
  ; chunk_id * 8
  .repeat 3
  asl a
  .endrepeat
  sta chunk_id
  tya
  sec
  sbc #1
  clc
  adc chunk_id
  tax
  ; Get strip id.
  lda level_chunks,x
  tax
  rts
.endproc


.proc LevelDataFillEntireScreen
  jsr PrepareRenderVertical
  ldx #0
Loop:
  jsr FillFullChunk
  inx
  cpx #FILL_LOOKAHEAD
  bne Loop
  rts
.endproc


.proc LevelDataUpdateScroll

  lda NMI_SCROLL_action
  beq Return

  jsr PrepareRenderVertical

  lda NMI_SCROLL_action
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
  sbc #1
  sta offset
  sta debug_11_offset
  ;
  mov target, NMI_SCROLL_target
  sta debug_12_target
  mov strip_id, NMI_SCROLL_strip_id
  sta debug_13_strip_id
  ;
  jsr PrepareRenderVertical
  jsr RenderNametableSingleStrip
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


.proc FillFullChunk
  txa
  pha

  stx target

  mov offset, #0

  lda level_data,x
  .repeat 3
  asl a
  .endrepeat
  tax
  lda level_chunks,x
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  inx
  lda level_chunks,x
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  inx
  lda level_chunks,x
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  inx
  lda level_chunks,x
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  inx
  lda level_chunks,x
  sta strip_id
  jsr RenderAttribute
  inx
  lda level_chunks,x
  sta strip_id
  jsr FillCollision

  pla
  tax

  rts
.endproc


; target
.proc RenderNametableChunk
  txa
  pha

  ; Offset of the strip to render, of which there are 4.
  mov offset, #0
Loop:
  jsr RenderNametableSingleStrip
  inc offset
  lda offset
  cmp #4
  bne Loop

  pla
  tax
  rts
.endproc


; Input:
;   offset   - Offset within the strip, 0..3
;   target   - Which strip in the nametable to render, 0..15
;   strip_id - Strip id to get level data from.
; Clobbers Y
.proc RenderNametableSingleStrip
  txa
  pha

  mov high_byte, #0
  ; Set up pointer to nametable data, strip_id * 24 + level_nt_column
  lda strip_id
  asl a
  clc
  adc strip_id
  .repeat 3
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

  ; Select address of the nametable at the top of the strip.
  lda target
  and #$07
  asl a
  asl a
  clc
  adc offset
  adc #$c0
  sta PPU_ADDR
  ; Render the strip, 24 elements.
  ldy #0
  ldx #24
RenderLoop:
  lda (pointer),y
  sta PPU_DATA
  iny
  dex
  bne RenderLoop

Return:
  pla
  tax
  rts
.endproc


; target
; strip_id
; Clobbers Y
.proc RenderAttribute
  txa
  pha

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
  adc #$c8
  tax
  ; Start at the top of the attributes, render 7 bytes.
  ldy #1
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
  cpy #$07
  bne Loop

  pla
  tax
  rts
.endproc


; target
; strip_id
; Clobbers Y
.proc FillCollision
  txa
  pha
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

  pla
  tax
  rts
.endproc



level_data:
.incbin ".b/level_data.dat"

level_chunks:
.incbin ".b/level_data_chunks.dat"

level_nt_column:
.incbin ".b/level_data_nt_column.dat"

level_attribute:
.incbin ".b/level_data_attribute.dat"

level_collision:
.incbin ".b/level_data_collision.dat"
