.export LevelClearData
.export LevelLoadInit
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
.importzp level_data_pointer, level_chunk_pointer
.importzp level_strip_table_pointer, level_spawn_pointer
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


;LevelClearData
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


;LevelLoadInit
.proc LevelLoadInit
  MovWord level_data_pointer, level1_data
  MovWord level_chunk_pointer, level1_chunk
  MovWord level_spawn_pointer, level1_spawn
  rts
.endproc


;LevelDataGetStripid
; input Y: Distance into the level data.
; input X: Action kind, 1..4 for nt, 5 for attr, 6 for collision
; output Y: Strip id
.proc LevelDataGetStripId
chunk_id = strip_id
  ; Get chunk_id.
  lda (level_data_pointer),y
  ; chunk_id * 8
  .repeat 3
  asl a
  .endrepeat
  sta chunk_id
  txa
  sec
  sbc #1
  clc
  adc chunk_id
  tay
  ; Get strip id.
  lda (level_chunk_pointer),y
  tay
  rts
.endproc


;LevelDataFillEntireScreen
; Clobbers Y
.proc LevelDataFillEntireScreen
  jsr PrepareRenderVertical
  ldy #0
Loop:
  jsr FillFullChunk
  iny
  cpy #FILL_LOOKAHEAD
  bne Loop
  rts
.endproc


;LevelDataUpdateScroll
.proc LevelDataUpdateScroll
  ; If no action, exit.
  lda NMI_SCROLL_action
  beq Return
  ; Render strips vertically (probably).
  jsr PrepareRenderVertical
  ; debug-only
  lda NMI_SCROLL_action
  sta debug_10_action
  ; Dispatch type of action.
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


;FillFullChunk
; Input Y: Distance into level data
.proc FillFullChunk
  ; push y
  tya
  pha

  sty target

  mov offset, #0

  lda (level_data_pointer),y
  .repeat 3
  asl a
  .endrepeat
  tay
  lda (level_chunk_pointer),y
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  iny
  lda (level_chunk_pointer),y
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  iny
  lda (level_chunk_pointer),y
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  iny
  lda (level_chunk_pointer),y
  sta strip_id
  jsr RenderNametableSingleStrip
  inc offset
  iny
  lda (level_chunk_pointer),y
  sta strip_id
  jsr RenderAttribute
  iny
  lda (level_chunk_pointer),y
  sta strip_id
  jsr FillCollision

  ; pop y
  pla
  tay

  rts
.endproc


; target
; Input Y...
.proc RenderNametableChunk
  tya
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
  tay
  rts
.endproc


; Input:
;   offset   - Offset within the strip, 0..3
;   target   - Which strip in the nametable to render, 0..15
;   strip_id - Strip id to get level data from.
; Preserves Y
.proc RenderNametableSingleStrip
  tya
  pha
  ; Get base nametable.
  ;TODO

  ;
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
  adc #<level1_nt_column
  sta pointer+0
  lda high_byte
  adc #>level1_nt_column
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
  tay
  rts
.endproc


; target
; strip_id
; Preserves Y
.proc RenderAttribute
  tya
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
  adc #<level1_attribute
  sta pointer+0
  lda high_byte
  adc #>level1_attribute
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
  tay
  rts
.endproc


; target
; strip_id
; Clobbers Y
.proc FillCollision
  tya
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
  adc #<level1_collision
  sta pointer+0
  lda high_byte
  adc #>level1_collision
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
  tay
  rts
.endproc



level1_data:
.incbin ".b/level_data.dat"

level1_chunk:
.incbin ".b/level_data_chunks.dat"

level1_nt_column:
.incbin ".b/level_data_nt_column.dat"

level1_attribute:
.incbin ".b/level_data_attribute.dat"

level1_collision:
.incbin ".b/level_data_collision.dat"

level1_spawn:
.incbin ".b/level_data_spawn.dat"
