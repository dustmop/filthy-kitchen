.export DrawPicture

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"

.importzp draw_picture_pointer, draw_sprite_pointer
.importzp draw_picture_id, draw_h, draw_v, draw_screen, draw_palette
.importzp values


attribute = values + $00


.segment "CODE"


.proc DrawPicture
  txa
  pha
  lda draw_screen
  bne FrameDone
  ; In sight, draw it.
  ldy draw_picture_id
FrameLoop:
  lda (draw_picture_pointer),y
  cmp #$fd
  blt DrawCommand
MetaCommand:
  cmp #$fd
  beq ResetHoriz
  cmp #$fe
  beq IncPalette
  cmp #$ff
  beq FrameDone
ResetHoriz:
  lda draw_h
  sec
  sbc #$10
  sta draw_h
IncPalette:
  inc draw_palette
  bne Increment
DrawCommand:
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
Increment:
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
  lda draw_picture_id
  asl a
  adc draw_picture_id
  tay
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


.include ".b/pictures.asm"
