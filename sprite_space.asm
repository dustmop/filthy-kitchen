.export SpriteSpaceInit
.export SpriteSpaceNext
.export SpriteSpaceAllocate
.export SpriteSpaceEraseAll
.export SpriteSpaceEraseAllAndSpriteZero
.export SpriteSpaceEnsure
.export SpriteSpaceSetLowPriority
.export SpriteSpaceRelax

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"

.importzp sprite_space_index, sprite_space_avail
.importzp sprite_space_force, sprite_space_force2, sprite_space_force3
.importzp values

max_idx    = values + $01
first_idx  = values + $02
second_idx = values + $03


NUM_RESERVED = 8

SPRITE_SPACE_ROTATE = $34
SPRITE_SPACE_NEXT   = $5c


.segment "CODE"


.proc SpriteSpaceInit
  mov sprite_space_index, #(NUM_RESERVED * $04)
  mov sprite_space_avail, _
  mov sprite_space_force, #$00
  mov sprite_space_force2, _
  mov sprite_space_force3, _
  rts
.endproc


.proc SpriteSpaceNext
  lda sprite_space_index
  clc
  adc #SPRITE_SPACE_ROTATE
  bcc Okay
  clc
  adc #(NUM_RESERVED * $04)
Okay:
  sta sprite_space_index
  sta sprite_space_avail
  jsr SpriteSpaceRelax
  rts
.endproc


.proc SpriteSpaceAllocate
  lda sprite_space_force
  beq Normal
Forced:
  tax
  mov sprite_space_force, sprite_space_force2
  mov sprite_space_force2, sprite_space_force3
  mov sprite_space_force3, #$00
  bpl Return
Normal:
  lda sprite_space_avail
  tax
  clc
  adc #SPRITE_SPACE_NEXT
  bcc Okay
  clc
  adc #(NUM_RESERVED * $04)
Okay:
  sta sprite_space_avail
Return:
  rts
.endproc


.proc SpriteSpaceEnsure
  mov sprite_space_force3, sprite_space_force2
  mov sprite_space_force2, sprite_space_force
  stx sprite_space_force
  rts
.endproc


.proc SpriteSpaceRelax
  mov sprite_space_force, #$00
  mov sprite_space_force2, _
  mov sprite_space_force3, _
  rts
.endproc


.proc SpriteSpaceSetLowPriority
  txa
  pha

  jsr SpriteSpaceAllocate
  stx max_idx

  jsr SpriteSpaceAllocate
  cpx max_idx
  blt NotMax1
NewMax1:
  mov first_idx, max_idx
  stx max_idx
  jmp GotMax1
NotMax1:
  stx first_idx
GotMax1:

  jsr SpriteSpaceAllocate
  cpx max_idx
  blt NotMax2
NewMax2:
  mov second_idx, max_idx
  stx max_idx
  jmp GotMax2
NotMax2:
  stx second_idx
GotMax2:
  ldx first_idx
  jsr SpriteSpaceEnsure
  ldx second_idx
  jsr SpriteSpaceEnsure
  ldx max_idx
  jsr SpriteSpaceEnsure

  pla
  tax

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


.proc SpriteSpaceEraseSpriteZero
  mov sprite_v, #$ff
  rts
.endproc


.proc SpriteSpaceEraseAllAndSpriteZero
  jsr SpriteSpaceEraseAll
  jmp SpriteSpaceEraseSpriteZero
.endproc
