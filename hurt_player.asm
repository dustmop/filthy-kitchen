.export HurtPlayer

.include "include.mov-macros.asm"
.include "sound.h.asm"

.importzp player_injury, player_iframe, player_gravity, player_gravity_low
.importzp player_health_delta, player_throw

.segment "CODE"

.proc HurtPlayer
  dec player_health_delta
  dey
  bne HurtPlayer
  lda #SFX_GOT_HURT
  jsr SoundPlay
  mov player_injury, #30
  mov player_iframe, #100
  mov player_gravity, #$fe
  mov player_gravity_low, #$00
  mov player_throw, _
  rts
.endproc
