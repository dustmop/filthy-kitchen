.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "render_action.h.asm"
.include "level_data.h.asm"
.include "general_mapper.h.asm"
.include "memory_layout.h.asm"
.include "gfx.h.asm"
.include "intro_outro.h.asm"
.include "famitone.h.asm"

.importzp bg_x_scroll, bg_y_scroll, main_yield, ppu_ctrl_current, debug_mode
.importzp player_removed
.import gameplay_palette, graphics0, graphics1

.export RESET, NMI

.segment "BOOT"


RESET:
  sei
  cld
  ldy #$40
  sty $4017
  dey
StackAndGraphics:
  ldx #$ff
  txs
  inx
  stx PPU_CTRL
  stx PPU_MASK
  stx $4010
  stx $4015

Wait0:
  bit PPU_STATUS
  bpl Wait0

ClearMemory:
  ldx #0
:
  mov {$000,x}, #0
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  mov {$200,x}, #$ff
  inx
  bne :-

Wait1:
  bit PPU_STATUS
  bpl Wait1

  jsr MemoryLayoutInit

  jsr ClearBothNametables

  lda #1
  ldx #<music_data
  ldy #>music_data
  jsr FamiToneInit

  ldx #<sfx_data
  ldy #>sfx_data
  jsr FamiToneSfxInit

  ; Exit to the intro
  jmp IntroScreen


NMI:
  pha
  txa
  pha
  tya
  pha
  ; Yield to next frame.
  mov main_yield, #$ff
  ; DMA sprites.
  mov OAM_ADDR, #$00
  mov OAM_DATA, #$02
  ; Execute any render actions that need to happen for level scrolling.
  jsr LevelDataUpdateScroll
  ; Render changes to the PPU.
  jsr RenderActionApplyAll
  ; Reset ppu pointer.
  lda #0
  sta PPU_ADDR
  sta PPU_ADDR
  ; Assign the scroll.
  lda #0
  sta PPU_SCROLL
  lda bg_y_scroll
  sta PPU_SCROLL
  ; Assign ppu control.
  lda ppu_ctrl_current
  sta PPU_CTRL
  pla
  tay
  pla
  tax
  pla
  rti
