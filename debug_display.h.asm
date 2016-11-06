.import MaybeDebugToggle
.import TintApplyToPpuMask

.macro SetTint color
  .if (.xmatch({color}, blue))
    lda #PPU_MASK_BLUE_TINT
  .elseif (.xmatch({color}, green))
    lda #PPU_MASK_GREEN_TINT
  .elseif (.xmatch({color}, red))
    lda #PPU_MASK_RED_TINT
  .elseif (.xmatch({color}, red_green))
    lda #(PPU_MASK_RED_TINT | PPU_MASK_GREEN_TINT)
  .elseif (.xmatch({color}, red_blue))
    lda #(PPU_MASK_RED_TINT | PPU_MASK_BLUE_TINT)
  .elseif (.xmatch({color}, green_blue))
    lda #(PPU_MASK_GREEN_TINT | PPU_MASK_BLUE_TINT)
  .elseif (.xmatch({color}, red_green_blue))
    lda #(PPU_MASK_RED_TINT | PPU_MASK_GREEN_TINT | PPU_MASK_BLUE_TINT)
  .elseif (.xmatch({color}, 0))
    lda #0
  .else
    .error "Could not find color"
  .endif
  jsr TintApplyToPpuMask
.endmacro

.macro DebugModeSetTint color
  .local Ignore
  bit debug_mode
  bpl Ignore
  SetTint color
Ignore:
.endmacro

.macro DebugModeWaitLoop num_loops
  .local WaitLoop
  bit debug_mode
  bpl Ignore
  ldx #num_loops
WaitLoop:
  nop
  nop
  nop
  nop
  nop
  nop
  dex
  bne WaitLoop
Ignore:
.endmacro
