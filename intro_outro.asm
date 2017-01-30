.export IntroScreen
.export OutroScreen

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "general_mapper.h.asm"
.include "read_controller.h.asm"
.include "gameplay.h.asm"
.include "render_action.h.asm"
.include "msg_catalog.h.asm"
.include "famitone.h.asm"

.importzp ppu_ctrl_current, buttons_press, lives
.importzp values
.importzp which_level
.importzp buttons
.import title_palette
.import title_graphics
.import game_over_palette
.import game_over_graphics

outer = values + 4
inner = values + 5

.segment "CODE"

.proc IntroScreen
  ; Load palette, which is defined in the prologue.
  ldx #<title_palette
  ldy #>title_palette
  jsr LoadPalette

  ldx #<title_graphics
  ldy #>title_graphics
  jsr LoadGraphicsCompressed

  ldx #MSG_PRESS
  jsr MsgRender
  ldx #MSG_START
  jsr MsgRender

  ; Load chr-ram from prg bank 1.
  lda #1
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam

  ; Play a song.
  ;lda #0
  ;jsr FamiToneMusicPlay

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

IntroLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
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
  jsr FamiToneMusicStop
  ; hold B to get level 9
  lda buttons
  and #BUTTON_B
  bne Level9
Level2:
  mov which_level, #2
  jmp ExitIntroScreen
Level9:
  mov which_level, #9
  jmp ExitIntroScreen

TransitionOut:
  jsr FamiToneMusicStop
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
  jsr FamiToneUpdate

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
  jsr FamiToneUpdate
  dec inner
  bne Loop
  rts
.endproc


.proc OutroScreen
  jsr RenderActionClear
  jsr ClearBothNametables

  ; Load palette, which is defined in the prologue.
  ldx #<game_over_palette
  ldy #>game_over_palette
  jsr LoadPalette

  ldx #<game_over_graphics
  ldy #>game_over_graphics
  jsr LoadGraphicsCompressed

  ; Load chr-ram from prg bank 1.
  lda #1
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam

  ; Play a song.
  ;lda #0
  ;jsr FamiToneMusicPlay

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

OutroLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  jmp OutroLoop
.endproc
