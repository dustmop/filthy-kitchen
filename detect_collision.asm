.export DetectCollisionInit
.export DetectCollisionWithGround
.export DetectCollisionWithWallLeft
.export DetectCollisionWithWallRight

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"

.import collision_map
.importzp values

pos_v        = values + $00
pos_h        = values + $01
pos_screen   = values + $02
row          = values + $03
corner       = values + $04
upper        = values + $05
collide_type = values + $06


COLLIDE_TYPE_GROUND = $55
COLLIDE_TYPE_WALL   = $aa


; DEBUGGING ONLY
debug_00_row     = $600 ; Row number
debug_01_upper   = $601 ; Upper byte (left or right half)
debug_02_col     = $602 ; Column number
debug_03_index   = $603 ; Index into collison map (row | column | upper)
debug_04_collide = $604 ; Byte at the collison map


.segment "CODE"


.proc DetectCollisionInit
  rts
.endproc


; Carry set = standing on ground
; Carry clear = in air
.proc DetectCollisionWithGround
  sta pos_screen
  sty pos_v
  stx pos_h

  mov collide_type, #COLLIDE_TYPE_GROUND

  ; (Y + 0x20) = bottom of player
  ; (Y + 0x18) = offset by a single tile
  ; (Y + 0x18) / 16 = block_y at bottom of player
  ; (Y + 0x18) / 16 * 16 = row of collision_map
  lda pos_v
  clc
  adc #$18
  and #$f0
  sta row
  sta debug_00_row

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


.proc DetectCollisionWithWallLeft
  sta pos_screen
  sty pos_v
  stx pos_h

  mov collide_type, #COLLIDE_TYPE_WALL

  ; (Y + 0x20) = bottom of player
  lda pos_v
  clc
  adc #$10
  and #$f0
  sta row

  ; Check lower-left corner.
  lda pos_h
  sta corner
  jsr CheckCollisionCorner
  bcs Success

Failure:
  clc
  rts
Success:
  sec
  rts
.endproc


.proc DetectCollisionWithWallRight
  sta pos_screen
  sty pos_v
  stx pos_h

  mov collide_type, #COLLIDE_TYPE_WALL

  ; (Y + 0x20) = bottom of player
  lda pos_v
  clc
  adc #$10
  and #$f0
  sta row

  ; Check lower-left corner.
  lda pos_h
  clc
  adc #$10
  sta corner
  jsr CheckCollisionCorner
  bcs Success

Failure:
  clc
  rts
Success:
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
  sta debug_01_upper

  ; X / 0x20 = column, which byte to lookup in the row (0..7)
  lda corner
  .repeat 5
  lsr a
  .endrepeat
  sta debug_02_col
  ; Combine with upper (left or right half) and row number.
  ora upper
  ora row
  sta debug_03_index
  tax

  ; (X / 8) % 4 = Offset into that byte
  lda corner
  .repeat 3
  lsr a
  .endrepeat
  and #$03
  tay

  lda collision_map,x
  sta debug_04_collide
  and bit_mask,y
  and collide_type
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
