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
.include "score_combo.h.asm"
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

  ldx #MSG_SCORE
  jsr MsgRender
  ldx #MSG_MARQUE_LIVES
  jsr MsgRender
  ldx #MSG_MARQUE_LEVEL
  jsr MsgRender
  ldx #MSG_ZERO_SCORE
  jsr MsgRender
  jsr RenderScore
  jsr RenderLevel
  jsr RenderLives

  jsr WaitVblankFlag

  lda which_level
  cmp #1
  beq Level1
  cmp #2
  beq Level2
  cmp #3
  beq Level3
  cmp #4
  beq Level4
  jmp Level5

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

Level5:
  ldx #MSG_YOU_DID_IT
  jsr MsgRender
  ldx #MSG_THE_KITCHEN_IS_CLEAN
  jsr MsgRender
  lda #1
  jsr FamiToneMusicPlay
  jmp LevelDone

LevelDone:

  lda #MEMORY_LAYOUT_BANK_SCREEN_CHR
  ldx #MEMORY_LAYOUT_NORMAL_POINTER
  jsr MemoryLayoutFillChrRam

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

  mov outer, #$0
  mov inner, #$90

MarqueLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  dec inner
  bne MarqueLoop

  lda which_level
  cmp #5
  beq MarqueLoop

  dec outer
  bpl MarqueLoop

TransitionOut:
  jsr FamiToneMusicStop

ExitMarqueScreen:
  jsr DisableDisplayAndNmi
  jmp GameplayMain
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
