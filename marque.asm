.export MarqueScreen

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
.import gameplay_palette
.import text_palette

outer = values + 4
inner = values + 5


.segment "CODE"

.proc MarqueScreen
  ; Load palette, which is defined in the prologue.
  ldx #<text_palette
  ldy #>text_palette
  jsr LoadPalette

  jsr ClearBothNametables

  lda which_level
  cmp #1
  beq Level1
  jmp Level2

Level1:
  ldx #MSG_THE_KITCHEN_IS_FILTHY
  jsr MsgRender
  ldx #MSG_FIND_THE_BROOM
  jsr MsgRender
  jmp LevelDone

Level2:
  ldx #MSG_KILL_ALL_THE_FLIES
  jsr MsgRender
  ldx #MSG_WATCH_OUT_FOR_DANGER
  jsr MsgRender
  jmp LevelDone

LevelDone:

  ; Load chr-ram from prg bank 1.
  lda #1
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

  mov outer, #$1
  mov inner, #$40

MarqueLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  dec inner
  bne MarqueLoop
  dec outer
  bpl MarqueLoop

TransitionOut:
  jsr FamiToneMusicStop

ExitMarqueScreen:
  jsr DisableDisplayAndNmi
  mov lives, #3
  jmp GameplayMain
.endproc
