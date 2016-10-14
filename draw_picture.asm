.export DrawPicture
.export swatter_picture_data
.export swatter_sprite_data

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"

.importzp draw_picture_pointer, draw_sprite_pointer
.importzp draw_picture_id, draw_h, draw_v, draw_palette
.importzp values


attribute = values + $00


.segment "CODE"


.proc DrawPicture
  txa
  pha
  ldy draw_picture_id
FrameLoop:
  lda (draw_picture_pointer),y
  cmp #$ff
  beq FrameDone
  and #$3f
  sta draw_picture_id
  lda (draw_picture_pointer),y
  and #$c0
  ora draw_palette
  sta attribute
  jsr DrawSinglePicture
  lda draw_h
  clc
  adc #8
  sta draw_h
  iny
  bne FrameLoop
FrameDone:
  pla
  tax
  rts
.endproc


.proc DrawSinglePicture
  tya
  pha
  ldy draw_picture_id
  jsr SpriteSpaceAllocate
  ; V
  lda (draw_sprite_pointer),y
  clc
  adc draw_v
  sta sprite_v,x
  iny
  ; H
  lda (draw_sprite_pointer),y
  clc
  adc draw_h
  sta sprite_h,x
  iny
  ; tile
  lda (draw_sprite_pointer),y
  sta sprite_tile,x
  ; attr
  lda attribute
  sta sprite_attr,x
  pla
  tay
  rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
swatter_picture_data:

swatter_dir_0: ; horizontal, offset=$00
.byte $00,$03,$ff

swatter_dir_1: ; diagonal up-right, offset=$03
.byte $06,$09,$ff

swatter_dir_2: ; vertical, offset=$06
.byte $0c,$ff

swatter_dir_3: ; diagonal up-left, offset=$08
.byte $49,$46,$ff

swatter_dir_4: ; horizontal, offset=$0b
.byte $43,$40,$ff

swatter_dir_5: ; diagonal down-left, offset=$0e
.byte $d2,$cf,$ff

swatter_dir_6: ; vertical, offset=$11
.byte $8c,$ff

swatter_dir_7: ; diagonal down-right, offset=$13
.byte $8f,$92,$ff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
swatter_sprite_data:

; swatter horizontal, left-half
; { v=6, h=0, tile=7 },  picture_id = $00
.byte $06, $00, $07
; swatter horizontal, right-half
; { v=-5, h=8, tile=9 }, picture_id = $03
.byte $fb, $00, $09
; swatter up-diag, left-half
; { v=9, h=-1, tile=3 }, picture_id = $06
.byte $09, $ff, $03
; swatter up-diag, right-half
; { v=-7, h=7, tile=5 }, picture_id = $09
.byte $f9, $ff, $05
; swatter vertical
; { v=0, h=4, tile=1 },  picture_id = $0c
.byte $00, $04, $01
; swatter down-diag, left-half
; { v=-9, h=-1, tile=3 }, picture_id = $0f
.byte $f7, $ff, $03
; swatter down-diag, right-half
; { v=7, h=7, tile=5 }, picture_id = $12
.byte $07, $ff, $05
