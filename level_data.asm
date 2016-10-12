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
  ; Select which nametable to render to, $2000 or $2400.
  lda target
  cmp #8
  bge HighTable
LowTable:
  mov upper_addr, #$20
  jmp GotTable
HighTable:
  mov upper_addr, #$24
GotTable:

  ; Set up pointer to nametable data.
  ; Units are 30[tiles] * 4[sub-strips] + 8[pad] = 128
  lda strip_id
  lsr a
  tax
  lda #<level_nt_column
  bcc HaveLowByte
  clc
  adc #$80
HaveLowByte:
  sta pointer+0
  txa
  adc #>level_nt_column
  sta pointer+1

  ; Count which sub-strip to render, of which there are 4.
  mov offset, #0
  ; Y is the position in the strip, starting at the top.
  ldy #0
EachStrip:
  mov PPU_ADDR, upper_addr
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
  ; Next sub-strip.
  inc offset
  lda offset
  cmp #4
  bne EachStrip

Return:
  rts
.endproc


.proc RenderAttribute
  ; Select which nametable to render attributes to, $23c0 or $27c0.
  lda target
  cmp #8
  bge HighTable
LowTable:
  mov upper_addr, #$23
  jmp GotTable
HighTable:
  mov upper_addr, #$27
GotTable:

  ; Set up pointer to attribute data. Treat offset:strip_id as 16-bit value.
  ; Units are 8 bytes.
  mov offset, #0
  lda strip_id
  .repeat 3
  asl a
  rol offset
  .endrepeat
  clc
  adc #<level_attribute
  sta pointer+0
  lda offset
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
  ; Set up pointer to collision data. Treat offset:strip_id as 16-bit value.
  ; Units are 15[bytes] + 1[pad] = 16.
  mov offset, #0
  lda strip_id
  .repeat 4
  asl a
  rol offset
  .endrepeat
  clc
  adc #<level_collision
  sta pointer+0
  lda offset
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
