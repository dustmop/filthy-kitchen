.export RandomSeedInit
.export RandomSeedInc
.export RandomEntropy
.export RandomGet

.include "include.mov-macros.asm"

.importzp random_value, buttons_press

.segment "CODE"


.proc RandomSeedInit
  mov random_value, #$c7
  rts
.endproc


.proc RandomSeedInc
  inc random_value
  jmp RandomAvoidZero
.endproc


.proc RandomEntropy
  lda random_value
  eor buttons_press
  sta random_value
  ; fall-through
.endproc


.proc RandomAvoidZero
  lda random_value
  bne Return
  inc random_value
Return:
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
  jsr RandomAvoidZero
  tya
  rts
.endproc
