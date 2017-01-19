.export IntroTitle

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "general_mapper.h.asm"
.include "read_controller.h.asm"
.include "gameplay.h.asm"
.include "render_action.h.asm"
.include "msg_catalog.h.asm"

.importzp ppu_ctrl_current, buttons_press, lives
.importzp values
.importzp which_level
.import title_palette
.import title_graphics

outer = values + 4
inner = values + 5

.segment "CODE"

.proc IntroTitle
  ; Load palette, which is defined in the prologue.
  ldx #<title_palette
  ldy #>title_palette
  jsr LoadPalette

  ldx #<title_graphics
  ldy #>title_graphics
  jsr LoadGraphicsNt0

  ldx #MSG_PRESS
  jsr MsgRender
  ldx #MSG_START
  jsr MsgRender

  ; Load chr-ram from prg bank 1.
  lda #1
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

IntroLoop:
  jsr WaitNewFrame
  jsr ReadController
  ; Start to exit normally.
  lda buttons_press
  and #BUTTON_START
  bne TransitionOut
  ; Select to exit fast to level 9 - debug feature.
  lda buttons_press
  and #BUTTON_SELECT
  bne TransitionFast
  beq IntroLoop

TransitionFast:
  mov which_level, #9
  jmp ExitIntroScreen

TransitionOut:
  mov outer, #12

OuterLoop:
  jsr ClearPressStart
  jsr WaitFramesForFlash
  ldx #MSG_PRESS
  jsr MsgRender
  ldx #MSG_START
  jsr MsgRender
  jsr WaitFramesForFlash
  dec outer
  bne OuterLoop
  jsr WaitNewFrame

ExitIntroScreen:
  jsr DisableDisplayAndNmi
  mov lives, #3
  jmp GameplayMain
.endproc


.proc ClearPressStart
  lda #11
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$22
  mov {render_action_addr_low,y}, #$ab
  ldx #0
Loop:
  mov {render_action_data,y}, #0
  iny
  inx
  cpx #11
  bne Loop
  rts
.endproc


.proc WaitFramesForFlash
  mov inner, #4
Loop:
  jsr WaitNewFrame
  dec inner
  bne Loop
  rts
.endproc
