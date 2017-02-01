.export IntroScreen
.export OutroScreen

.include "include.controller.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "general_mapper.h.asm"
.include "memory_layout.h.asm"
.include "read_controller.h.asm"
.include "gameplay.h.asm"
.include "marque.h.asm"
.include "sprite_space.h.asm"
.include "object_list.h.asm"
.include "render_action.h.asm"
.include "msg_catalog.h.asm"
.include "famitone.h.asm"
.include "sound.h.asm"
.include "endboss.h.asm"

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
wings_frame = values + 6

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

  lda #MEMORY_LAYOUT_BANK_SCREEN_CHR
  ldx #MEMORY_LAYOUT_NORMAL_POINTER
  jsr MemoryLayoutFillChrRam

  jsr CreateFlyWings

  ; Play a song.
  lda #0
  jsr FamiToneMusicPlay

  jsr SpriteSpaceInit

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay
  jsr Disable8x16

IntroLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  jsr SpriteSpaceEraseAll
  jsr SpriteSpaceNext
  jsr ObjectListUpdate
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
  ; hold A to get level 9
  lda buttons
  and #BUTTON_A
  bne Level4
  ; hold down to get boss
  lda buttons
  and #BUTTON_DOWN
  bne LevelBoss
Level2:
  mov which_level, #2
  jmp ExitFast
Level4:
  mov which_level, #4
  jmp ExitFast
LevelBoss:
  mov which_level, #BOSS_LEVEL
  jmp ExitFast

TransitionOut:
  jsr FamiToneMusicStop
  lda #SFX_PRESS_START
  jsr SoundPlay
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
  mov which_level, #1
  jmp MarqueScreen

ExitFast:
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

  lda #MEMORY_LAYOUT_BANK_SCREEN_CHR
  ldx #MEMORY_LAYOUT_NORMAL_POINTER
  jsr MemoryLayoutFillChrRam

  ; Play a song.
  ;lda #0
  ;jsr FamiToneMusicPlay

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

OutroLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  jmp OutroLoop
.endproc


.proc Disable8x16
  lda ppu_ctrl_current
  and #($ff & ~PPU_CTRL_SPRITE_8x16)
  sta ppu_ctrl_current
  sta PPU_CTRL
  rts
.endproc


.proc CreateFlyWings
  jsr ObjectListInit

  jsr ObjectAllocate
  mov {object_kind,x}, #OBJECT_KIND_WING
  mov {object_v,x}, #$9c
  mov {object_h,x}, #$13
  ldy #0
  jsr ObjectConstructor

  jsr ObjectAllocate
  mov {object_kind,x}, #OBJECT_KIND_WING
  mov {object_v,x}, #$9c
  mov {object_h,x}, #$24
  ldy #1
  jsr ObjectConstructor

  jsr ObjectAllocate
  mov {object_kind,x}, #OBJECT_KIND_WING
  mov {object_v,x}, #$9c
  mov {object_h,x}, #$cc
  ldy #2
  jsr ObjectConstructor

  jsr ObjectAllocate
  mov {object_kind,x}, #OBJECT_KIND_WING
  mov {object_v,x}, #$9c
  mov {object_h,x}, #$dd
  ldy #3
  jsr ObjectConstructor

  rts
.endproc
