.export SoundPlay

.include "famitone.h.asm"

.importzp sfx_num

FT_SFX_CH0 = 0


.segment "CODE"

.proc SoundPlay
  sta sfx_num
  txa
  pha
  tya
  pha
  lda sfx_num
  ldx #FT_SFX_CH0
  jsr FamiToneSfxPlay
  pla
  tay
  pla
  tax
  rts
.endproc
