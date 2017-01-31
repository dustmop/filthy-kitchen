.export FadeSetFullBlack
.export FadeInGameplay
.export FadeInBoss

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "render_action.h.asm"
.include "famitone.h.asm"
.include "gfx.h.asm"

.importzp values
offset = values + $00
count = values + $01
outer = values + $02

FADE_TIME_NUM_FRAMES = 6


.segment "CODE"


.proc FadeSetFullBlack
  jsr PrepareRenderHorizontal
  mov PPU_ADDR, #$3f
  mov PPU_ADDR, #$00
  lda #$0f
  ldx #$00
Loop:
  sta PPU_DATA
  inx
  cpx #$20
  bne Loop
  rts
.endproc


.proc FadeInGameplay
  mov offset, #$40
  jmp FadeIn
.endproc


.proc FadeInBoss
  mov offset, #$a0
  jmp FadeIn
.endproc


.proc FadeIn
  mov outer, #3
FadeLoop:
  ; Wait a couple of frames.
  lda #FADE_TIME_NUM_FRAMES
  jsr WaitNumFrames
  ; Render action to set the palette.
  lda #$20
  jsr AllocateRenderAction
  mov {render_action_addr_high,y}, #$3f
  mov {render_action_addr_low,y}, #$00
  ; Copy $20 bytes.
  mov count, #$20
  ldx offset
CopyLoop:
  lda fader_pal,x
  sta render_action_data,y
  iny
  inx
  dec count
  bpl CopyLoop
  ; Bring the offset back, continue fading.
  lda offset
  sec
  sbc #$20
  sta offset
  dec outer
  bne FadeLoop
FadeDone:
  rts
.endproc


fader_pal:
.incbin ".b/fader_pal.dat"


.proc WaitNumFrames
  sta count
Loop:
  jsr WaitNewFrame
  jsr FamiToneUpdate
  dec count
  bpl Loop
  rts
.endproc
