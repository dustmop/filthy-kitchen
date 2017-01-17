.export BroomMaybeCreate
.export BroomDispatch

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"
.include ".b/pictures.h.asm"

.importzp camera_h, camera_screen
.importzp have_spawned_broom
.importzp draw_screen
.importzp values

.import object_data_extend


.segment "CODE"


.proc BroomMaybeCreate
  jsr CreateOnce
Return:
  rts
.endproc


.proc CreateOnce
  lda have_spawned_broom
  bne Return

  jsr SpawnBroom
  bcc Return
  inc have_spawned_broom
  mov {object_screen,x}, #$03
  mov {object_h,x}, #$c0
  mov {object_v,x}, #$60
  jmp Return

Return:
  rts
.endproc


.proc SpawnBroom
  jsr ObjectAllocate
  bcs Failure
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_BROOM
  mov {object_life,x}, #$ff
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc BroomDispatch

.scope CollisionWithPlayer
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  ; TODO: Finish the level.
  jsr ObjectFree
  jmp Return
Next:
.endscope

  ; Draw position.
  lda object_h,x
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

BROOM_TOP_TILE       = $85
BROOM_MIDDLE_TILE    = $87
BROOM_GLOW_A_TILE    = $89
BROOM_GLOW_B_TILE    = $8b
BROOM_GLOW_C_TILE    = $8d
BROOM_MOP_LEFT_TILE  = $8f
BROOM_MOP_RIGHT_TILE = $91
