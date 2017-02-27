.export WingConstructor
.export WingExecute
.export WingDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"

.importzp values
offset_h = values + 0
count = values + 1
draw_attr = values + 2
draw_tile = values + 3

.import object_data_extend
wing_attr = object_data_extend + $00


WING_BASE_TILE = $8c


.segment "CODE"


.proc WingConstructor
  lda wing_attr_table,y
  sta wing_attr,x
  mov {object_life,x}, #$f0
  rts
.endproc


.proc WingExecute

  mov offset_h, #0

  ; Draw position.
  lda object_h,x
  sta draw_h
  lda object_v,x
  sta draw_v

  lda object_life,x
  and #$07
  lsr a
  tay
  lda wing_animation,y
  sta draw_tile
  lda wing_attr,x
  sta draw_attr

  ; If horizontal flip is set, change the horizontal offset.
  and #$40
  beq :+
  mov offset_h, #8
:

  lda object_life,x
  cmp #$d0
  bne :+
  lda #$f0
  sta object_life,x
:

  mov count, #0
DrawLoop:
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  clc
  adc offset_h
  sta sprite_h,x
  lda draw_tile
  sta sprite_tile,x
  lda draw_attr
  sta sprite_attr,x

  inc count
  lda count
  cmp #4
  beq Return

  inc draw_tile

  lda offset_h
  eor #$08
  sta offset_h

  lda count
  cmp #2
  bne Okay
  lda draw_v
  clc
  adc #8
  sta draw_v
Okay:

  jmp DrawLoop

Return:
  rts
.endproc


WingDraw = WingExecute


wing_attr_table:
.byte $40
.byte $20
.byte $60
.byte $00

wing_animation:
.byte WING_BASE_TILE + 0
.byte WING_BASE_TILE + 4
.byte WING_BASE_TILE + 8
.byte WING_BASE_TILE + 4
