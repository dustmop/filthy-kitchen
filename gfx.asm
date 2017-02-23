.segment "BOOT"

.export ClearBothNametables
.export LoadGraphicsNt0, LoadGraphicsNt1, LoadPalette, LoadSpritelist
.export LoadGraphicsCompressed, RenderGraphicsCompressed
.export EnableNmi, WaitNewFrame, WaitVblankFlag, EnableDisplay
.export EnableNmiThenWaitNewFrameThenEnableDisplay
.export DisableDisplay, DisableDisplayAndNmi, TintApplyToPpuMask
.export PrepareRenderVertical, PrepareRenderHorizontal

.import chr_data
.importzp ppu_mask_current, ppu_ctrl_current, main_yield, color
.importzp decompress_count, decompress_limit

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"

.importzp NMI_pointer
.importzp NMI_values
pointer = NMI_pointer
next    = NMI_values + $00


.proc ClearBothNametables
  bit PPU_STATUS
  ldx #8
  ldy #0
  mov PPU_ADDR, #$20
  mov PPU_ADDR, #$00
Loop:
  sta PPU_DATA
  iny
  bne Loop
  dex
  bne Loop
  rts
.endproc


.proc LoadGraphicsNt0
  lda #$20
  jmp LoadGraphicsSingleNametable
.endproc

.proc LoadGraphicsNt1
  lda #$24
  fallt LoadGraphicsSingleNametable
.endproc


.proc LoadGraphicsSingleNametable
  bit PPU_STATUS
  stx pointer+0
  sty pointer+1
  ldx #4
  ldy #0
  sta PPU_ADDR
  mov PPU_ADDR, #0
Loop:
  lda (pointer),y
  sta PPU_DATA
  iny
  bne Loop
  inc pointer+1
  dex
  bne Loop
  rts
.endproc


.proc LoadGraphicsCompressed
  bit PPU_STATUS
  stx pointer+0
  sty pointer+1
  mov decompress_limit, #$ff
  mov PPU_ADDR, #$20
  mov PPU_ADDR, #$00
  jmp Decompressor
.endproc


.proc RenderGraphicsCompressed
  sta decompress_limit
  mov decompress_count, #$00
  jmp Decompressor
.endproc


.proc Decompressor
  ldy #0
OuterLoop:
  lda decompress_limit
  bmi GetSequenceType
  cmp decompress_count
  beq OuterDone
  blt OuterDone
GetSequenceType:
  lda (pointer),y
  beq OuterDone
  bmi RepeatSequence
  cmp #$40
  bge IncSequence
LiteralSequence:
  tax
  clc
  adc decompress_count
  sta decompress_count
  iny
LiteralLoop:
  lda (pointer),y
  sta PPU_DATA
  iny
  dex
  bne LiteralLoop
  beq OuterNext
IncSequence:
  iny
  and #$3f
  tax
  clc
  adc decompress_count
  sta decompress_count
  lda (pointer),y
  iny
IncLoop:
  sta PPU_DATA
  clc
  adc #1
  dex
  bne IncLoop
  beq OuterNext
RepeatSequence:
  iny
  and #$3f
  beq SetPpuAddrSequence
  tax
  clc
  adc decompress_count
  sta decompress_count
  lda (pointer),y
  iny
RepeatLoop:
  sta PPU_DATA
  dex
  bne RepeatLoop
  beq OuterNext
SetPpuAddrSequence:
  lda (pointer),y
  iny
  sta PPU_ADDR
  lda (pointer),y
  iny
  sta PPU_ADDR
OuterNext:
  sty next
  lda pointer+0
  clc
  adc next
  sta pointer+0
  lda pointer+1
  adc #0
  sta pointer+1
  ldy #0
  jmp OuterLoop
OuterDone:
  rts
.endproc


.proc LoadPalette
  bit PPU_STATUS
  stx pointer+0
  sty pointer+1
  lda #$3f
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldy #0
Loop:
  lda (pointer),y
  sta PPU_DATA
  iny
  cpy #$20
  bne Loop
  rts
.endproc


.proc LoadSpritelist
  stx pointer+0
  sty pointer+1
  ldy #0
Loop:
  lda (pointer),y
  cmp #$ff
  beq Done
  sta $200,y
  iny
  bne Loop
Done:
  rts
.endproc


; Turn on the nmi, then wait for the next frame before enabling the display.
; This prevents a partially rendered frame from appearing at start-up.
.proc EnableNmiThenWaitNewFrameThenEnableDisplay
  jsr EnableNmi
  jsr WaitNewFrame
  fallt EnableDisplay
.endproc


.proc EnableDisplay
  lda ppu_mask_current
  ora #(PPU_MASK_SHOW_SPRITES | PPU_MASK_SHOW_BG | PPU_MASK_NOCLIP_SPRITES | PPU_MASK_NOCLIP_BG)
  sta PPU_MASK
  sta ppu_mask_current
  rts
.endproc


.proc EnableNmi
  lda #(PPU_CTRL_NMI_ENABLE | PPU_CTRL_SPRITE_1000)
  sta PPU_CTRL
  sta ppu_ctrl_current
  cli
  rts
.endproc


.proc WaitVblankFlag
Wait:
  bit PPU_STATUS
  bpl Wait
  rts
.endproc


.proc WaitNewFrame
  mov main_yield, #0
WaitLoop:
  bit main_yield
  bpl WaitLoop
  mov main_yield, #0
  rts
.endproc


.proc DisableDisplay
  lda ppu_mask_current
  and #($ff & ~PPU_MASK_SHOW_SPRITES & ~PPU_MASK_SHOW_BG)
  sta PPU_MASK
  sta ppu_mask_current
  rts
.endproc


.proc DisableDisplayAndNmi
  lda #0
  sta PPU_MASK
  sta ppu_mask_current
  lda ppu_ctrl_current
  and #($ff & ~PPU_CTRL_NMI_ENABLE)
  sta PPU_CTRL
  sta ppu_ctrl_current
  rts
.endproc


.proc TintApplyToPpuMask
  sta color
  lda ppu_mask_current
  and #PPU_MASK_TINT_DISABLE
  ora color
  sta PPU_MASK
  sta ppu_mask_current
  rts
.endproc


.proc PrepareRenderVertical
  bit PPU_STATUS
  lda ppu_ctrl_current
  ora #PPU_CTRL_VRAM_INC_32
  sta ppu_ctrl_current
  sta PPU_CTRL
  rts
.endproc


.proc PrepareRenderHorizontal
  bit PPU_STATUS
  lda ppu_ctrl_current
  and #($ff & ~PPU_CTRL_VRAM_INC_32)
  sta ppu_ctrl_current
  sta PPU_CTRL
  rts
.endproc


