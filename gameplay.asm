.export GameplayMain

.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "general_mapper.h.asm"
.include "intro_outro.h.asm"
.include "marque.h.asm"
.include "gfx.h.asm"
.include "endboss.h.asm"
.include "fader.h.asm"
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
.importzp level_complete, which_level, objects_only_draw
.import gameplay_palette, graphics0, graphics1


.segment "CODE"


GameplayMain:
.scope GameplayMain

  lda which_level
  cmp #BOSS_LEVEL
  beq BossChrRam
NormalChrRam:
  ; Load chr-ram from prg bank 0.
  lda #0
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam
  jmp ChrRamDone
BossChrRam:
  ; Load chr-ram from prg bank 0.
  lda #2
  jsr GeneralMapperPrgBank8000
  jsr LoadChrRam
ChrRamDone:

  ; Load level data from prg bank 4.
  lda #4
  jsr GeneralMapperPrgBank8000
  jsr PlayerClearData
  jsr LevelClearData

  jsr HudDataFill
  jsr HudMessagesRender

  mov objects_only_draw, #0

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

  ; Display sprites.
  jsr CameraUpdate
  jsr HudElemsPut
  jsr PlayerDraw

.scope FadeInFromBlack
  jsr FadeSetFullBlack
  jsr EnableNmiThenWaitNewFrameThenEnableDisplay
  ; TODO: Annoyingly, the above call clobbers the ppu_ctrl values.
  lda ppu_ctrl_current
  ora #PPU_CTRL_SPRITE_8x16
  sta ppu_ctrl_current
  sta PPU_CTRL
  lda which_level
  cmp #BOSS_LEVEL
  beq Boss
Gameplay:
  jsr FadeInGameplay
  jmp Next
Boss:
  jsr FadeInBoss
Next:
.endscope

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
  inc which_level
  jmp MarqueScreen


GameplayGameOverExit:
  ; TODO: Fade out.
  jsr DisableDisplayAndNmi
  jmp OutroScreen
