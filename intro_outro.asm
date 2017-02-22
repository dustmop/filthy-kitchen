.export IntroScreen
.export OutroScreen

.include "include.controller.asm"
.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"
.include "random.h.asm"
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
.importzp main_yield
.importzp buttons
.import title_palette
.import title_graphics
.import game_over_palette
.import game_over_graphics

MAX_LEVEL = 4

outer        = values + 4
inner        = values + 5
wings_frame  = values + 6
code_dist    = values + 7
special_code = values + 8

.segment "CODE"

.proc IntroScreen
  jsr WaitVblankFlag

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
  ldx #MSG_COPYRIGHT
  jsr MsgRender

  lda #MEMORY_LAYOUT_BANK_SCREEN_CHR
  ldx #MEMORY_LAYOUT_NORMAL_POINTER
  jsr MemoryLayoutFillChrRam

  jsr CreateFlyWings

  mov code_dist, #0
  mov special_code, _

  mov which_level, #1
  mov lives, #3

  ; Play a song.
  lda #0
  jsr FamiToneMusicPlay

  jsr SpriteSpaceInit

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay
  jsr Disable8x16

IntroLoop:
  jsr WaitNewFrameWhileIncreasingRandomSeed
  jsr FamiToneUpdate
  jsr SpriteSpaceEraseAll
  jsr SpriteSpaceNext
  jsr ObjectListUpdate
  jsr ReadController
  ; Start to exit normally.
  lda buttons_press
  and #BUTTON_START
  bne TransitionOut
  ; Build a special code.
  jsr AccumulateSpecialCode
  ; If special code.
  lda special_code
  beq IntroLoop
CodeIsActive:
  lda buttons_press
  and #BUTTON_LEFT
  bne LevelDec
  lda buttons_press
  and #BUTTON_RIGHT
  bne LevelInc
  beq IntroLoop
LevelDec:
  dec which_level
  bne LevelSet
  mov which_level, #MAX_LEVEL
  bpl LevelSet
LevelInc:
  inc which_level
  lda which_level
  cmp #(MAX_LEVEL + 1)
  blt LevelSet
  mov which_level, #1
LevelSet:
  jsr RenderLevelSelection
  jmp IntroLoop

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
  jmp MarqueScreen

ExitFast:
  jsr DisableDisplayAndNmi
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

  jsr CreateFlyWings
  jsr SpriteSpaceInit

  jsr EnableNmiThenWaitNewFrameThenEnableDisplay

OutroLoop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  jsr SpriteSpaceEraseAll
  jsr SpriteSpaceNext
  jsr ObjectListUpdate
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


.proc AccumulateSpecialCode
  bit special_code
  bmi Return
  ; Check each bit one at a time.
  mov outer, #8
  lda buttons_press
  beq Return
Loop:
  lsr a
  bcs GotButton
  dec outer
  beq Return
  bne Loop
GotButton:
  ; If more than one button pressed, exit.
  bne EraseCode
  ; Compare the pressed button to the expected sequence.
  lda buttons_press
  ldy code_dist
  cmp code_sequence,y
  bne EraseCode
  ; Correct value inputted, advance the code distance.
  inc code_dist
  lda code_dist
  cmp #CODE_LENGTH
  beq SpecialCodeComplete
  rts
EraseCode:
  mov code_dist, #0
  ; Special case.
  lda buttons_press
  cmp code_sequence+0
  bne Return
  ; Start after step 1
  inc code_dist
Return:
  rts
SpecialCodeComplete:
  lda #SFX_MAKE_STARS
  jsr SoundPlay
  mov special_code, #$ff
  ldx #MSG_SELECT_LEVEL
  jsr MsgRender
  jsr RenderLevelSelection
  rts
.endproc


KEY_RIGHT  = 1
KEY_LEFT   = 2
KEY_DOWN   = 4
KEY_UP     = 8
KEY_START  = $10
KEY_SELECT = $20
KEY_B      = $40
KEY_A      = $80


code_sequence:
.byte KEY_DOWN, KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_B, KEY_A, KEY_DOWN
CODE_LENGTH = * - code_sequence


.proc RenderLevelSelection
  lda #1
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$22
  mov {render_action_addr_low,y},  #$73
  lda which_level
  clc
  adc #$30
  sta render_action_data,y
  rts
.endproc


.proc WaitNewFrameWhileIncreasingRandomSeed
  mov main_yield, #0
WaitLoop:
  jsr RandomSeedInc
  bit main_yield
  bpl WaitLoop
  mov main_yield, #0
  rts
.endproc
