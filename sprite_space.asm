.export SpriteSpaceInit
.export SpriteSpaceNext
.export SpriteSpaceAllocate
.export SpriteSpaceEraseAll
.export SpriteSpaceEnsure

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"

.importzp sprite_space_index, sprite_space_avail
.importzp sprite_space_force, sprite_space_force2
.importzp values

NUM_RESERVED = 3


.segment "CODE"


.proc SpriteSpaceInit
  mov sprite_space_index, #(NUM_RESERVED * $04)
  mov sprite_space_avail, _
  mov sprite_space_force, #$00
  mov sprite_space_force2, _
  rts
.endproc


.proc SpriteSpaceNext
  lda sprite_space_index
  clc
  adc #$10
  bcc Okay
  clc
  adc #(NUM_RESERVED * $04)
Okay:
  sta sprite_space_index
  sta sprite_space_avail
  mov sprite_space_force, #$00
  mov sprite_space_force2, _
  rts
.endproc


.proc SpriteSpaceAllocate
  lda sprite_space_force
  beq Normal
Forced:
  tax
  mov sprite_space_force, sprite_space_force2
  mov sprite_space_force2, #$00
  bpl Return
Normal:
  lda sprite_space_avail
  tax
  clc
  adc #$50
  bcc Okay
  clc
  adc #(NUM_RESERVED * $04)
Okay:
  sta sprite_space_avail
Return:
  rts
.endproc


.proc SpriteSpaceEnsure
  mov sprite_space_force2, sprite_space_force
  stx sprite_space_force
  rts
.endproc


.proc SpriteSpaceEraseAll
  ; Erase all of the sprites in shadow OAM.
  lda #$ff
  ldx #$00
  ldy #$10
  ; Skip the sprite zero.
  bpl StartAfterZero
Loop:
  sta sprite_v+$00,x
StartAfterZero:
  sta sprite_v+$40,x
  sta sprite_v+$80,x
  sta sprite_v+$c0,x
  inx
  inx
  inx
  inx
  dey
  bne Loop
  rts
.endproc
