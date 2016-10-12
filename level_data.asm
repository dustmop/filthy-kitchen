.export LevelDataFillEntireScreen

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"

.importzp pointer, ppu_ctrl_current
.importzp values
.import collision_map

strip_id   = values + $00
target     = values + $01
offset     = values + $02
upper_addr = values + $03
count      = values + $04
high_byte  = values + $05

.segment "CODE"


.proc LevelDataFillEntireScreen
  jsr PrepareRender
  ldx #0
Loop:
  jsr FillFullStrip
  inx
  cpx #$10
  bne Loop
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
  ; Count which sub-strip to render, of which there are 4.
  mov count, #0
Loop:
  jsr RenderNametableSingleSubstrip
  inc count
  lda count
  cmp #4
  bne Loop
  rts
.endproc


; Input:
;   A[reg]   - Offset within the strip, 0..3
;   target   - Which strip in the nametable to render, 0..15
;   strip_id - Strip id to get level data from.
.proc RenderNametableSingleSubstrip
  sta offset

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
  ldx target
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
