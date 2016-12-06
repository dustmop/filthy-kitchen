.export DrawPicture

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"

.importzp draw_picture_pointer, draw_sprite_pointer
.importzp draw_picture_id, draw_h, draw_v, draw_screen, draw_palette
.importzp draw_curr_h, draw_curr_v
.importzp values


DRAW_PICTURE_APPEND = $fe
DRAW_PICTURE_DONE = $ff


attribute = values + $00
skip_row = values + $01


.segment "CODE"


.proc DrawPicture
  txa
  pha
  mov skip_row, #0
  lda draw_screen
  bne FrameDone
  ; In sight, draw it.
  mov draw_curr_h, draw_h
  mov draw_curr_v, draw_v
  ldy draw_picture_id
FrameLoop:
  lda (draw_picture_pointer),y
  cmp #DRAW_PICTURE_DONE
  beq FrameDone
  cmp #DRAW_PICTURE_APPEND
  bne DrawCommand
MetaCommand:
  mov skip_row, #0
  mov draw_curr_h, draw_h
  mov draw_curr_v, draw_v
  inc draw_palette
  bne Increment
DrawCommand:
  bit skip_row
  bmi Increment
  and #$3f
  sta draw_picture_id
  lda (draw_picture_pointer),y
  and #$c0
  ora draw_palette
  sta attribute
  jsr DrawSingleSprite
  lda draw_curr_h
  clc
  adc #8
  sta draw_curr_h
  bcc Increment
  mov skip_row, #$ff
Increment:
  iny
  bne FrameLoop
FrameDone:
  pla
  tax
  rts
.endproc


.proc DrawSingleSprite
  tya
  pha
  lda draw_picture_id
  asl a
  adc draw_picture_id
  tay
  jsr SpriteSpaceAllocate
  ; V
  lda draw_curr_v
  eor #$80
  clc
  adc (draw_sprite_pointer),y
  eor #$80
  bvs Clear
  sta sprite_v,x
  iny
  ; H
  lda draw_curr_h
  eor #$80
  clc
  adc (draw_sprite_pointer),y
  eor #$80
  bvs Clear
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
Clear:
  lda #$ff
  sta sprite_v,x
  pla
  tay
  rts
.endproc


.include ".b/pictures.asm"
