.export BroomExecute
.export BroomDraw
.export BroomExplodeIntoStars

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"
.include "flash.h.asm"
.include ".b/pictures.h.asm"

.importzp camera_h, camera_screen
.importzp level_complete
.importzp draw_screen
.importzp values
.import flash_priority

.import object_data_extend


.segment "CODE"


.proc BroomExecute

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope CollisionWithPlayer
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  mov level_complete, #1
  jmp Return
Next:
.endscope

Draw:
  lda level_complete
  beq Ready
  ; Flash the broom.
  and #$0f
  tay
  lda flash_priority,y
  beq Return

Ready:
  ; Draw position.
  lda object_h,x
  clc
  adc #6
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  ldy object_frame,x
  lda broom_animate_v_offset,y
  clc
  adc object_v,x
  sta draw_v

  ; Animation.
  lda #PICTURE_ID_BROOM
  sta draw_picture_id
  MovWord draw_picture_pointer, broom_picture_data
  MovWord draw_sprite_pointer, broom_sprite_data
  mov draw_palette, #1
  ; Draw the sprites.
  jsr DrawPicture

Return:
  rts
.endproc


BroomDraw = BroomExecute::Draw


.proc BroomExplodeIntoStars
  jsr ObjectListGetLast
Loop:
  lda object_kind,x
  cmp #OBJECT_KIND_BROOM
  bne Increment
Explode:
  lda object_v,x
  clc
  adc #$10
  sta draw_v
  lda object_h,x
  clc
  adc #$08
  sta draw_h
  mov draw_screen, {object_screen,x}
  jsr ObjectFree
  ldy #0
  jsr CreateStar
  ldy #1
  jsr CreateStar
  ldy #2
  jsr CreateStar
  ldy #3
  jsr CreateStar
  rts
Increment:
  dex
  bpl Loop
  rts
.endproc


.proc CreateStar
  jsr ObjectAllocate
  bcc Return
  mov {object_kind,x}, #OBJECT_KIND_STAR
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  jsr ObjectConstructor
Return:
  rts
.endproc


broom_animate_v_offset:
.byte 0
.byte 0
.byte 1
.byte 2
.byte 3
.byte 3
.byte 2
.byte 1


; TODO: Pictures can't correctly process broom.
PICTURE_ID_BROOM = 0
broom_picture_data:
.byte $00,$01,$02,$03,$04,$fe,$05,$06,$ff
broom_sprite_data:
;       y,  x, tile
.byte $00,$0a         ,BROOM_TOP_TILE
.byte $0a,$08-$08     ,BROOM_MIDDLE_TILE
.byte $1a,$00-$10+$100,BROOM_GLOW_A_TILE
.byte $1a,$0a-$18+$100,BROOM_GLOW_B_TILE
.byte $28,$06-$20+$100,BROOM_GLOW_C_TILE
.byte $1a,$01         ,BROOM_MOP_LEFT_TILE
.byte $1a,$09-$08     ,BROOM_MOP_RIGHT_TILE

BROOM_TOP_TILE       = $9b
BROOM_MIDDLE_TILE    = BROOM_TOP_TILE + 2
BROOM_GLOW_A_TILE    = BROOM_TOP_TILE + 4
BROOM_GLOW_B_TILE    = BROOM_TOP_TILE + 6
BROOM_GLOW_C_TILE    = BROOM_TOP_TILE + 8
BROOM_MOP_LEFT_TILE  = BROOM_TOP_TILE + 10
BROOM_MOP_RIGHT_TILE = BROOM_TOP_TILE + 12
