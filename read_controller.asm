.export ReadController, ReadInputPort0, ReadInputPort1

.include "include.sys.asm"

.importzp buttons, buttons_last, buttons_press

.segment "CODE"


.proc ReadController
  jsr ReadInputPort0
  lda buttons_last
  eor #$ff
  and buttons
  sta buttons_press
  lda buttons
  sta buttons_last
  rts
.endproc


.proc ReadInputPort0
  ldy #1
  sty INPUT_PORT_0
  sty buttons
  dey
  sty INPUT_PORT_0
Loop:
  lda INPUT_PORT_0
  lsr a
  rol buttons
  lda INPUT_PORT_0
  lsr a
  rol buttons
  bcc Loop
Done:
  rts
.endproc


.proc ReadInputPort1
  ldy #1
  sty INPUT_PORT_0
  sty buttons
  dey
  sty INPUT_PORT_0
Loop:
  lda INPUT_PORT_1
  lsr a
  rol buttons
  lda INPUT_PORT_1
  lsr a
  rol buttons
  bcc Loop
Done:
  rts
.endproc
