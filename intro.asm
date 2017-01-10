.export IntroTitle

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "general_mapper.h.asm"
.include "read_controller.h.asm"
.include "gameplay.h.asm"

.importzp ppu_ctrl_current, buttons_press, lives
.import title_palette
.import title_graphics

.segment "CODE"

.proc IntroTitle
  ; Load palette, which is defined in the prologue.
  ldx #<title_palette
  ldy #>title_palette
  jsr LoadPalette

  ldx #<title_graphics
  ldy #>title_graphics
  jsr LoadGraphicsNt0

  ; Load chr-ram from prg bank 1.
  lda #1
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

IntroLoop:
  jsr WaitNewFrame
  jsr ReadController
  lda buttons_press
  and #BUTTON_START
  beq IntroLoop

  jsr WaitNewFrame
  jsr DisableDisplayAndNmi
  mov lives, #3
  jmp GameplayMain
.endproc
