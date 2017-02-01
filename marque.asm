.export MarqueScreen

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "general_mapper.h.asm"
.include "memory_layout.h.asm"
.include "read_controller.h.asm"
.include "sprite_space.h.asm"
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

  jsr SpriteSpaceEraseAllAndSpriteZero
  jsr ClearBothNametables

  lda which_level
  cmp #1
  beq Level1
  cmp #2
  beq Level2
  cmp #3
  beq Level3
  jmp Level4

Level1:
  ldx #MSG_THE_KITCHEN_IS
  jsr MsgRender
  ldx #MSG_FIND_THE_BROOM
  jsr MsgRender
  ldx #MSG_AND_CLEAN_IT_UP
  jsr MsgRender
  jmp LevelDone

Level2:
  ldx #MSG_KILL_ALL_THE_FLIES
  jsr MsgRender
  ldx #MSG_WATCH_OUT_FOR
  jsr MsgRender
  ldx #MSG_AND_APPLIANCES
  jsr MsgRender
  jmp LevelDone

Level3:
  ldx #MSG_KEEP_GOING_ALMOST
  jsr MsgRender
  ldx #MSG_GET_COMBO_KILLS
  jsr MsgRender
  ldx #MSG_TO_EARN_HIGH
  jsr MsgRender
  jmp LevelDone

Level4:
  ldx #MSG_WARNING
  jsr MsgRender
  ldx #MSG_BOSS_FLY_IS_APPROACHING
  jsr MsgRender
  ldx #MSG_RESOLVE_YOUR_BATTLE
  jsr MsgRender
  jmp LevelDone

LevelDone:

  lda #MEMORY_LAYOUT_BANK_SCREEN_CHR
  ldx #MEMORY_LAYOUT_NORMAL_POINTER
  jsr MemoryLayoutFillChrRam

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

  mov outer, #$0
  mov inner, #$50

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
