.export GameplayMain

.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "general_mapper.h.asm"
.include "gfx.h.asm"
.include "read_controller.h.asm"
.include "player.h.asm"
.include "camera.h.asm"
.include "hud_display.h.asm"
.include "level_data.h.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "debug_display.h.asm"
.include "score_combo.h.asm"
.include "fly.h.asm"
.include "food.h.asm"
.include "dirt.h.asm"
.include "utensils.h.asm"
.include "random.h.asm"
.include "health.h.asm"

.importzp bg_x_scroll, bg_y_scroll, main_yield, ppu_ctrl_current, debug_mode
.importzp player_removed
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

  jsr HudDataFill
  jsr LevelDataFillEntireScreen
  jsr HealthSetMax

  jsr RandomSeedInit
  jsr PlayerInit
  jsr CameraInit
  jsr ObjectListInit
  jsr SpriteSpaceInit

  jsr HudSplitAssign

  ; Turn on the nmi, then wait for the next frame before enabling the display.
  ; This prevents a partially rendered frame from appearing at start-up.
  jsr EnableNmi
  jsr WaitNewFrame
  jsr EnableDisplayAndNmi

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

  DebugModeSetTint red_green
  jsr FlyListUpdate

  DebugModeSetTint blue
  jsr PlayerUpdate

  DebugModeSetTint red
  jsr CameraUpdate

  DebugModeSetTint green_blue
  jsr FoodMaybeCreate
  jsr DirtMaybeCreate
  jsr UtensilsMaybeCreate

  DebugModeSetTint green
  jsr ObjectListUpdate

  DebugModeSetTint red_blue
  jsr PlayerDraw

  DebugModeSetTint red
  jsr FlashEarnedCombo

  DebugModeSetTint green
  jsr HealthApplyDelta

  DebugModeSetTint 0
  jsr MaybeDebugToggle

  lda player_removed
  cmp #150
  bne :+
  jsr DisableDisplayAndNmi
  jmp GameplayMain
:

  jmp GameplayLoop
.endscope
