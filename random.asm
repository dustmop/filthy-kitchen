.export RandomSeedInit
.export RandomEntropy
.export RandomGet

.include "include.mov-macros.asm"

.importzp random_value, buttons_press

.segment "CODE"


.proc RandomSeedInit
  mov random_value, #$c7
.endproc


.proc RandomEntropy
  lda random_value
  eor buttons_press
  sta random_value
  rts
.endproc


.proc RandomGet
  ldy random_value
  tya
  asl a
  bcc DontXor
  eor #$1d
DontXor:
  sta random_value
  tya
  rts
.endproc
