.export GameplayMain

.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "general_mapper.h.asm"
.include "intro_outro.h.asm"
.include "gfx.h.asm"
.include "read_controller.h.asm"
.include "player.h.asm"
.include "camera.h.asm"
.include "hud_display.h.asm"
.include "level_data.h.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "debug_display.h.asm"
.include "spawn_offscreen.h.asm"
.include "score_combo.h.asm"
.include "fly.h.asm"
.include "food.h.asm"
.include "dirt.h.asm"
.include "utensils.h.asm"
.include "broom.h.asm"
.include "random.h.asm"
.include "health.h.asm"
.include "msg_catalog.h.asm"
.include "famitone.h.asm"

.importzp bg_x_scroll, bg_y_scroll, main_yield, ppu_ctrl_current, debug_mode
.importzp player_removed, lives
.importzp level_complete, objects_only_draw
.import gameplay_palette, graphics0, graphics1


.segment "CODE"


GameplayMain:
.scope GameplayMain
  ; Load palette, which is defined in the prologue.
  ldx #<gameplay_palette
  ldy #>gameplay_palette
  jsr LoadPalette

  ; Load chr-ram from prg bank 0.
  lda #0
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam

  ; Load level data from prg bank 4.
  lda #4
  jsr GeneralMapperPrgBank8000
  jsr PlayerClearData
  jsr LevelClearData

  jsr HudDataFill
  ldx #MSG_HEALTH
  jsr MsgRender
  ldx #MSG_LIVES
  jsr MsgRender
  ldx #MSG_SCORE
  jsr MsgRender
  ldx #MSG_COMBO
  jsr MsgRender
  ldx #MSG_ZERO_SCORE
  jsr MsgRender
  ldx #MSG_ZERO_COMBO
  jsr MsgRender

  jsr ObjectListInit
  jsr SpriteSpaceInit
  jsr SpawnOffscreenInit

  jsr LevelLoadInit
  jsr LevelDataFillEntireScreen
  jsr SpawnOffscreenFillEntireScreen
  jsr HealthSetMax

  jsr RandomSeedInit
  jsr PlayerInit
  jsr CameraInit

  jsr HudSplitAssign
  jsr RenderScore

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

  lda ppu_ctrl_current
  ora #PPU_CTRL_SPRITE_8x16
  sta ppu_ctrl_current
  sta PPU_CTRL

GameplayLoop:
  jsr WaitNewFrame

  DebugModeWaitLoop 160

  DebugModeSetTint red
  jsr ReadController

  DebugModeSetTint blue
  jsr SpriteSpaceNext

  DebugModeSetTint green
  jsr RandomEntropy

  DebugModeSetTint green_blue
  jsr SpriteSpaceEraseAll

  DebugModeSetTint red_blue
  jsr HudElemsPut

  DebugModeSetTint 0
  jsr HudSplitWait

  lda level_complete
  beq HandleEngine

.scope LevelEnding
  inc level_complete
  lda level_complete
  beq IsZero
  cmp #$48
  beq DestroyBroom
  cmp #$c0
  bne Ready
  jmp GameplayExit
IsZero:
  mov level_complete, #1
  jmp Ready
DestroyBroom:
  jsr BroomExplodeIntoStars
Ready:
  mov objects_only_draw, #1
  bne EngineReady
.endscope

HandleEngine:

  DebugModeSetTint red_green
  jsr FlyListUpdate

  DebugModeSetTint blue
  jsr PlayerUpdate

  DebugModeSetTint red
  jsr CameraUpdate

  DebugModeSetTint green_blue
  jsr SpawnOffscreenUpdate

EngineReady:

  DebugModeSetTint green
  jsr ObjectListUpdate

  DebugModeSetTint red_blue
  jsr PlayerDraw

  DebugModeSetTint red
  jsr FlashEarnedCombo

  DebugModeSetTint green
  jsr HealthApplyDelta

  DebugModeSetTint blue
  jsr FamiToneUpdate

  DebugModeSetTint 0
  jsr MaybeDebugToggle

  lda player_removed
  cmp #150
  bne :+
  dec lives
  beq GameplayGameOverExit
  jsr DisableDisplayAndNmi
  jmp GameplayMain
:

  jmp GameplayLoop
.endscope


GameplayExit:
  jsr DisableDisplayAndNmi
  jmp GameplayExit


GameplayGameOverExit:
  ; TODO: Fade out.
  jsr DisableDisplayAndNmi
  jmp OutroScreen
