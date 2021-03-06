.export LevelClearData
.export LevelLoadInit
.export LevelDataGetStripId, LevelDataFillEntireScreen, LevelDataUpdateScroll
.export SetLevelBank, RevertLevelBank

.include "include.const.asm"
.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "endboss.h.asm"
.include "memory_layout.h.asm"
.include "general_mapper.h.asm"

.importzp ppu_ctrl_current
.importzp NMI_pointer
.importzp NMI_values
.importzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.importzp level_state_begin, level_state_end
.importzp level_data_pointer, level_chunk_pointer
.importzp level_table_of_contents_pointer, level_spawn_pointer
.importzp level_max_screen, level_has_entrance_door, level_has_infinite_flies
.importzp level_player_start_v
.importzp level_bank
.importzp which_level
.import collision_map

BOSS_LEVEL = MAX_LEVEL

FILL_LOOKAHEAD = 9

STRIP_TABLE_NT_COLUMN = 0
STRIP_TABLE_ATTRIBUTE = 2
STRIP_TABLE_COLLISION = 4

pointer = NMI_pointer
values = NMI_values

strip_id   = values + $00
target     = values + $01
offset     = values + $02
upper_addr = values + $03
high_byte  = values + $04

; DEBUGGING ONLY
debug_10_action   = $610
debug_11_offset   = $611
debug_12_target   = $612
debug_13_strip_id = $613


.segment "BOOT"


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
  lda which_level
  cmp #1
  beq Load1
  cmp #2
  beq Load2
  cmp #3
  beq Load3
  cmp #4
  jeq Load4
  cmp #BOSS_LEVEL
  jeq LoadBoss

Load1:
  MovWord level_data_pointer, level1_data
  MovWord level_chunk_pointer, level1_chunk
  MovWord level_spawn_pointer, level1_spawn
  MovWord level_table_of_contents_pointer, level1_table_of_contents
  mov level_max_screen, #LEVEL1_LAST_SCREEN
  mov level_has_entrance_door, level1_meta+0
  mov level_has_infinite_flies, level1_meta+1
  mov level_player_start_v, level1_meta+2
  mov level_bank, #MEMORY_LAYOUT_BANK_LEVEL_DAT
  rts

Load2:
  MovWord level_data_pointer, level2_data
  MovWord level_chunk_pointer, level2_chunk
  MovWord level_spawn_pointer, level2_spawn
  MovWord level_table_of_contents_pointer, level2_table_of_contents
  mov level_max_screen, #LEVEL2_LAST_SCREEN
  mov level_has_entrance_door, level2_meta+0
  mov level_has_infinite_flies, level2_meta+1
  mov level_player_start_v, level2_meta+2
  mov level_bank, #MEMORY_LAYOUT_BANK_LEVEL_DAT
  rts

Load3:
  MovWord level_data_pointer, level3_data
  MovWord level_chunk_pointer, level3_chunk
  MovWord level_spawn_pointer, level3_spawn
  MovWord level_table_of_contents_pointer, level3_table_of_contents
  mov level_max_screen, #LEVEL3_LAST_SCREEN
  mov level_has_entrance_door, level3_meta+0
  mov level_has_infinite_flies, level3_meta+1
  mov level_player_start_v, level3_meta+2
  mov level_bank, #MEMORY_LAYOUT_BANK_LEVEL_DAT
  rts

Load4:
  MovWord level_data_pointer, level4_data
  MovWord level_chunk_pointer, level4_chunk
  MovWord level_spawn_pointer, level4_spawn
  MovWord level_table_of_contents_pointer, level4_table_of_contents
  mov level_max_screen, #LEVEL4_LAST_SCREEN
  mov level_has_entrance_door, level4_meta+0
  mov level_has_infinite_flies, level4_meta+1
  mov level_player_start_v, level4_meta+2
  mov level_bank, #MEMORY_LAYOUT_BANK_LEVEL_DAT
  rts

LoadBoss:
  mov level_max_screen, #0
  mov level_has_entrance_door, #0
  mov level_has_infinite_flies, #0
  mov level_player_start_v, #$a8
  MovWord level_spawn_pointer, no_spawn
  mov level_bank, #MEMORY_LAYOUT_BANK_LEVEL_DAT
  rts

.endproc


;LevelDataGetStripid
; input Y: Distance into the level data.
; input X: Action kind, 1..4 for nt, 5 for attr, 6 for collision
; output Y: Strip id
.proc LevelDataGetStripId
  jsr SetLevelBank
chunk_id = strip_id
  mov high_byte, #0
  ; Get chunk_id.
  lda (level_data_pointer),y
  ; chunk_id * 8
  .repeat 3
  asl a
  rol high_byte
  .endrepeat
  sta chunk_id
  txa
  sec
  sbc #1
  clc
  adc chunk_id
  clc
  adc level_chunk_pointer+0
  sta pointer+0
  lda level_chunk_pointer+1
  adc high_byte
  sta pointer+1
  ldy #0
  ; Get strip id.
  lda (pointer),y
  tay
  jsr RevertLevelBank
  rts
.endproc


;LevelDataFillEntireScreen
; Clobbers Y
.proc LevelDataFillEntireScreen
  lda which_level
  cmp #BOSS_LEVEL
  bne Normal
  ;
  jsr EndBossFillGraphics
  rts
Normal:
  jsr SetLevelBank
  jsr PrepareRenderVertical
  ldy #0
Loop:
  jsr FillFullChunk
  iny
  cpy #FILL_LOOKAHEAD
  bne Loop
  jsr RevertLevelBank
  rts
.endproc


;LevelDataUpdateScroll
.proc LevelDataUpdateScroll
  jsr SetLevelBank
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
  jsr RevertLevelBank
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
  ; Get base pointer to nametable data.
  ldy #STRIP_TABLE_NT_COLUMN ; 0
  lda (level_table_of_contents_pointer),y
  sta pointer+0
  iny
  lda (level_table_of_contents_pointer),y
  sta pointer+1
  ;
  mov high_byte, #0
  ; Set up pointer to nametable data, strip_id * 8 + level_nt_column
  lda strip_id
  .repeat 3
  asl a
  rol high_byte
  .endrepeat
  clc
  adc pointer+0
  sta pointer+0
  lda high_byte
  adc pointer+1
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
  ; Render the strip, 22 elements after being decompressed.
  lda #22
  jsr RenderGraphicsCompressed

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

  ; Get base pointer to attribute data.
  ldy #STRIP_TABLE_ATTRIBUTE ; 2
  lda (level_table_of_contents_pointer),y
  sta pointer+0
  iny
  lda (level_table_of_contents_pointer),y
  sta pointer+1

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
  adc pointer+0
  sta pointer+0
  lda high_byte
  adc pointer+1
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
  ; Get base pointer to collision data.
  ldy #STRIP_TABLE_COLLISION ; 4
  lda (level_table_of_contents_pointer),y
  sta pointer+0
  iny
  lda (level_table_of_contents_pointer),y
  sta pointer+1

  ; Set up pointer to collision data. Treat high_byte:strip_id as 16-bit value.
  ; Units are 15[bytes] + 1[pad] = 16.
  mov high_byte, #0
  lda strip_id
  .repeat 4
  asl a
  rol high_byte
  .endrepeat
  clc
  adc pointer+0
  sta pointer+0
  lda high_byte
  adc pointer+1
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


.proc SetLevelBank
  txa
  pha
  tya
  pha
  lda level_bank
  jsr GeneralMapperPrg8000ToC000
  pla
  tay
  pla
  tax
  rts
.endproc


.proc RevertLevelBank
  txa
  pha
  tya
  pha
  lda #MEMORY_LAYOUT_BANK_MAIN_CODE
  jsr GeneralMapperPrg8000ToC000
  pla
  tay
  pla
  tax
  rts
.endproc


level1_meta:
.byte $80, 0, $b8

level2_meta:
level3_meta:
.byte 0, 0, $a8

level4_meta:
.byte 0, 0, $68

.segment "DAT2"

.include ".b/level1_data.asm"
.include ".b/level2_data.asm"
.include ".b/level3_data.asm"
.include ".b/level4_data.asm"

no_spawn:
.byte $ff,$ff,$ff,$ff
