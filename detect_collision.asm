.export DetectCollisionInit
.export DetectCollisionWithBackground

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"

.import collision_map
.importzp values

pos_v      = values + $00
pos_h      = values + $01
pos_screen = values + $02
row        = values + $03
corner     = values + $04
upper      = values + $05

; DEBUGGING ONLY
temp0 = $400 ; Row number
temp1 = $401 ; Upper byte (left or right half)
temp2 = $402 ; Column number
temp3 = $403 ; Index into collison map (row | column | upper)
temp4 = $404 ; Byte at the collison map


.segment "CODE"


.proc DetectCollisionInit
  rts
.endproc


; Carry set = standing on ground
; Carry clear = in air
.proc DetectCollisionWithBackground
  sta pos_screen
  sty pos_v
  stx pos_h

  ; (Y + 0x20) = bottom of player
  ; (Y + 0x18) = offset by a single tile
  ; (Y + 0x18) / 16 = block_y at bottom of player
  ; (Y + 0x18) / 16 * 16 = row of collision_map
  lda pos_v
  clc
  adc #$18
  and #$f0
  sta row
  sta temp0

  ; Check lower-left corner.
  lda pos_h
  clc
  adc #$3
  sta corner
  jsr CheckCollisionCorner
  bcs Success

  ; Check lower-right corner.
  lda pos_h
  clc
  adc #$9
  sta corner
  jsr CheckCollisionCorner
  bcs Success

Failure:
  clc
  rts
Success:
  lda row
  sec
  sbc #$18
  sec
  rts
.endproc


.proc CheckCollisionCorner
  lda pos_screen
  adc #0
  and #$01
  .repeat 3
  asl a
  .endrepeat
  sta upper
  sta temp1

  ; X / 0x20 = column, which byte to lookup in the row (0..7)
  lda corner
  .repeat 5
  lsr a
  .endrepeat
  sta temp2
  ; Combine with upper (left or right half) and row number.
  ora upper
  ora row
  sta temp3
  tax

  ; (X / 8) % 4 = Offset into that byte
  lda corner
  .repeat 3
  lsr a
  .endrepeat
  and #$03
  tay

  lda collision_map,x
  sta temp4
  and bit_mask,y
  ; 1 = Platform top, stops vertical movement
  ; 2 = Wall, stops horizontal movement (TODO: Implement me)
  beq Failure
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


bit_mask:
.byte $03,$0c,$30,$c0
