.export MarqueScreen

.include "include.controller.asm"
.include "include.const.asm"
.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "general_mapper.h.asm"
.include "memory_layout.h.asm"
.include "read_controller.h.asm"
.include "sprite_space.h.asm"
.include "gameplay.h.asm"
.include "render_action.h.asm"
.include "score_combo.h.asm"
.include "msg_catalog.h.asm"
.include "famitone.h.asm"
.include "endboss.h.asm"

.importzp ppu_ctrl_current, buttons_press, lives
.importzp values
.importzp which_level
.importzp buttons
.import gameplay_palette
.import text_palette
.import RESET

outer = values + 4
inner = values + 5

BOSS_LEVEL = MAX_LEVEL


.segment "CODE"

.proc MarqueScreen
  jsr WaitVblankFlag

  ; Load palette, which is defined in the prologue.
  ldx #<text_palette
  ldy #>text_palette
  jsr LoadPalette

  jsr SpriteSpaceEraseAllAndSpriteZero
  jsr ClearBothNametables

  ldx #MSG_SCORE
  jsr MsgRender
  ldx #MSG_ZERO_SCORE
  jsr MsgRender
  jsr RenderScore
  ldx #MSG_MARQUE_LIVES
  jsr MsgRender
  jsr RenderLives
  lda which_level
  cmp #MAX_LEVEL
  bge :+
  ldx #MSG_MARQUE_LEVEL
  jsr MsgRender
  jsr RenderLevel
:
  jsr RenderActionApplyAll

  lda which_level
  cmp #1
  beq Level1
  cmp #2
  beq Level2
  cmp #3
  beq Level3
  cmp #4
  beq Level4
  cmp #BOSS_LEVEL
  beq EndBoss
  jmp Finale

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

  ; TODO: Messages for levels 4 and 5.
Level4:
  ldx #MSG_TODO
  jsr MsgRender
  jmp LevelDone

EndBoss:
  ldx #MSG_WARNING
  jsr MsgRender
  ldx #MSG_BOSS_FLY_IS_APPROACHING
  jsr MsgRender
  ldx #MSG_RESOLVE_YOUR_BATTLE
  jsr MsgRender
  jmp LevelDone

Finale:
  ldx #MSG_YOU_DID_IT
  jsr MsgRender
  ldx #MSG_THE_KITCHEN_IS_CLEAN
  jsr MsgRender
  lda #1
  jsr FamiToneMusicPlay
  jmp LevelDone

LevelDone:

  ldx #TITLE_MEMORY_LAYOUT
  jsr MemoryLayoutFillChrRam

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

  mov outer, #$0
  mov inner, #$90

  lda which_level
  cmp #(MAX_LEVEL + 1)
  bne :+
  mov inner, #1
:

MarqueLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  dec inner
  bne MarqueLoop

  lda which_level
  cmp #(MAX_LEVEL + 1)
  beq MaybeTestController

  dec outer
  bpl MarqueLoop

TransitionOut:
  jsr FamiToneMusicStop

ExitMarqueScreen:
  jsr DisableDisplayAndNmi
  jmp GameplayMain

MaybeTestController:
  mov inner, #1
  jsr ReadController
  lda buttons_press
  and #BUTTON_START
  beq MarqueLoop
TransitionToReset:
  jsr FamiToneMusicStop
  jmp RESET
.endproc


.proc RenderLives
  lda #1
  jsr AllocateRenderAction
  RenderActionSetYX 3, 10
  lda lives
  clc
  adc #$30
  sta render_action_data+0,y
  rts
.endproc


.proc RenderLevel
  lda #1
  jsr AllocateRenderAction
  RenderActionSetYX 11, 19
  lda which_level
  clc
  adc #$30
  sta render_action_data+0,y
  rts
.endproc
