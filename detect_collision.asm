.export DetectCollisionInit
.export DetectCollisionWithBackground

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"

.importzp values

pos_v = values + $00
pos_h = values + $01
row   = values + $02

temp0 = $300
temp1 = $301
temp2 = $302



.segment "CODE"


.proc DetectCollisionInit
  rts
.endproc


; Carry set = standing on ground
; Carry clear = in air
.proc DetectCollisionWithBackground
  sty pos_v
  stx pos_h

  ; (Y + 0x20) = bottom of player
  ; (Y + 0x20) / 16 = block_y at bottom of player
  ; (Y + 0x20) / 16 * 4 = row of collision_data
  lda pos_v
  clc
  adc #$18
  .repeat 2
  lsr a
  .endrepeat
  and #$fc
  sta row
  sta temp0

  ; X / 0x40 = which byte to lookup in the row (0..3)
  lda pos_h
  .repeat 6
  lsr a
  .endrepeat
  sta temp1
  ora row
  sta temp2
  tax

  ; (X / 8) % 8 = offset into that byte
  lda pos_h
  .repeat 3
  lsr a
  .endrepeat
  and #$07
  tay

  lda collision_data,x
  and bit_mask,y
  beq Failure
Success:
  lda row
  .repeat 2
  asl a
  .endrepeat
  sec
  sbc #$18
  sec
  rts
Failure:
  clc
  rts
.endproc


bit_mask:
.byte $01, $02, $04, $08, $10, $20, $40, $80


collision_data:
.incbin ".b/collision.dat"
