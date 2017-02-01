.export GameplayMain

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "general_mapper.h.asm"
.include "memory_layout.h.asm"
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
.importzp combo_low, combo_medium
.import gameplay_palette, graphics0, graphics1


.segment "CODE"


GameplayMain:
.scope GameplayMain

  lda which_level
  cmp #BOSS_LEVEL
  beq BossChrRam
NormalChrRam:
  ; Load chr-ram from prg bank 0.
  lda #MEMORY_LAYOUT_BANK_GAMEPLAY_CHR
  ldx #MEMORY_LAYOUT_NORMAL_POINTER
  jsr MemoryLayoutFillChrRam
  jmp ChrRamDone
BossChrRam:
  ; Load chr-ram from prg bank 0.
  lda #MEMORY_LAYOUT_BANK_GAMEPLAY_CHR
  ldx #MEMORY_LAYOUT_BOSS_POINTER
  jsr MemoryLayoutFillChrRam
ChrRamDone:

  jsr PlayerClearData
  jsr LevelClearData

  jsr HudDataFill
  jsr HudMessagesRender

  mov objects_only_draw, #0
  mov combo_low, #0
  mov combo_medium, #0

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
  jsr EndBossInit

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
  jsr EndBossSwatterHandle
Next:
.endscope

.scope StartSong
  ldy which_level
  beq Next
  cpy #5
  bge Next
  lda level_song,y
  jsr FamiToneMusicPlay
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

  jsr EndBossUpdate

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


level_song:
.byte $ff
.byte 1
.byte 2
.byte 0
.byte 3
