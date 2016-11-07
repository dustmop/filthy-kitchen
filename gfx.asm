.segment "CODE"

.export LoadGraphicsNt0, LoadGraphicsNt1, LoadPalette, LoadSpritelist
.export EnableDisplayAndNmi, EnableDisplay, EnableNmi, WaitNewFrame
.export DisableDisplay, TintApplyToPpuMask
.export PrepareRenderVertical, PrepareRenderHorizontal

.importzp ppu_mask_current, ppu_ctrl_current, main_yield, color

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"

.importzp pointer

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

.proc EnableDisplayAndNmi
  lda #(PPU_CTRL_NMI_ENABLE | PPU_CTRL_SPRITE_1000)
  sta PPU_CTRL
  sta ppu_ctrl_current
  lda #(PPU_MASK_SHOW_SPRITES | PPU_MASK_SHOW_BG | PPU_MASK_NOCLIP_SPRITES | PPU_MASK_NOCLIP_BG)
  sta PPU_MASK
  sta ppu_mask_current
  cli
  rts
.endproc

.proc EnableNmi
  lda #(PPU_CTRL_NMI_ENABLE | PPU_CTRL_SPRITE_1000)
  sta PPU_CTRL
  sta ppu_ctrl_current
  cli
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

.proc EnableDisplay
  lda ppu_mask_current
  ora #(PPU_MASK_SHOW_SPRITES | PPU_MASK_SHOW_BG)
  sta PPU_MASK
  sta ppu_mask_current
  rts
.endproc

.proc DisableDisplay
  lda ppu_mask_current
  and #($ff & ~PPU_MASK_SHOW_SPRITES & ~PPU_MASK_SHOW_BG)
  sta PPU_MASK
  sta ppu_mask_current
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


