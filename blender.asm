.export BlenderConstructor
.export BlenderExecute
.export BlenderDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.tiles.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "trash_gunk.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"
.include "hurt_player.h.asm"

.importzp camera_h, camera_screen
.importzp draw_screen, draw_h, draw_v, draw_frame
.importzp player_v, player_h, player_screen
.importzp player_iframe
.importzp elec_sfx
.importzp values


AGGRO_DISTANCE = $40


BLENDER_STATE_NORMAL = 0
BLENDER_STATE_VOLATILE = 1
BLENDER_STATE_JUMP = 2
BLENDER_STATE_EMPTY = 3


orig_h = values + $00

.import object_data_extend
blender_state = object_data_extend + $00
blender_count = object_data_extend + $10


.segment "CODE"


.proc BlenderConstructor
  mov {blender_state,x}, #0
  mov {blender_count,x}, _
  rts
.endproc


.proc BlenderExecute

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope MaybeBecomeVolatile
  ; If not in state normal, skip me.
  lda blender_state,x
  bne Next
  ; Check distance from player.
  lda object_h,x
  sec
  sbc player_h
  sta delta_h
  lda object_screen,x
  sbc player_screen
  bmi Negative
  beq HaveDelta
  bpl Next
Negative:
  lda delta_h
  eor #$ff
  sta delta_h
HaveDelta:
  lda delta_h
  cmp #AGGRO_DISTANCE
  bge Next
IsClose:
  mov {blender_state,x}, #BLENDER_STATE_VOLATILE
  mov {blender_count,x}, #0
Next:
.endscope

.scope HandleVolatility
  lda blender_state,x
  cmp #BLENDER_STATE_VOLATILE
  bne Next
  inc blender_count,x
  lda blender_count,x
  cmp #$20
  bne Next
  ; Next state
  ; TODO: Jump state instead.
  mov {blender_state,x}, #BLENDER_STATE_EMPTY
  mov {blender_count,x}, #0
  ; Create gunk.
  lda object_v,x
  pha
  sec
  sbc #$10
  sta object_v,x
  ldy #0
  jsr TrashGunkSpawnTwoInOppositeDirections
  pla
  sta object_v,x
Next:
.endscope

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  ldy #2
  jsr HurtPlayer
Next:
.endscope

Draw:
  ; Draw position.
  mov draw_v, {object_v,x}
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  jne Return

  ; Handle state drawing differences.
.scope DrawStateChange
  lda blender_state,x
  beq Next
  cmp #BLENDER_STATE_VOLATILE
  beq Volatile
  ; TODO: More states
  bne Next
Volatile:
  lda blender_count,x
  and #$2
  beq ShakeLeft
ShakeRight:
  ; TODO: Screen
  inc draw_h
  jmp Next
ShakeLeft:
  dec draw_h
Next:
.endscope

  mov orig_h, draw_h

  lda blender_state,x
  asl a
  tay

  ; Left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda blender_animation,y
  sta sprite_tile,x
  lda #$02
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  iny

  ; Right side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda blender_animation,y
  sta sprite_tile,x
  lda #$02
  sta sprite_attr,x

  mov draw_h, orig_h

  lda draw_v
  sec
  sbc #16
  sta draw_v

  ; If jump or empty state, don't draw the top of the blender.
  cpy #4
  bge Return

  ; Top left
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #BLENDER_TOP_TILE
  sta sprite_tile,x
  lda #$00
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  ; Top right.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #BLENDER_TOP_TILE
  sta sprite_tile,x
  lda #$40
  sta sprite_attr,x

Return:
  rts
.endproc


BlenderDraw = BlenderExecute::Draw



blender_animation:
.byte BLENDER_FULL_TILE_0  ; normal
.byte BLENDER_FULL_TILE_1  ; normal
.byte BLENDER_FULL_TILE_0  ; volatile
.byte BLENDER_FULL_TILE_1  ; volatile
.byte BLENDER_JUMP_TILE_0  ; jump
.byte BLENDER_JUMP_TILE_1  ; jump
.byte BLENDER_EMPTY_TILE_0 ; empty
.byte BLENDER_EMPTY_TILE_1 ; empty

