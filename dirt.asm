.export DirtMaybeCreate
.export DirtDispatch

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp have_spawned_dirt
.importzp draw_screen, draw_h, draw_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta
.importzp values

.import object_data_extend


DIRTY_KIND_TILE_LEFT = $81
DIRTY_KIND_TILE_RIGHT = $83


.segment "CODE"


.proc DirtMaybeCreate
MaybeSpawnApple:
  lda camera_h
  cmp #$c0
  blt Return
SpawnDirtySink:
  lda #0
  jsr CreateOnce
Return:
  rts
.endproc


.proc CreateOnce
  cmp have_spawned_dirt
  bne Return

  cmp #0
  beq SpawnDirtySink
  bne Return

SpawnDirtySink:
  jsr SpawnDirt
  bcc Return
  inc have_spawned_dirt
  mov {object_screen,x}, #$01
  mov {object_h,x}, #$c7
  mov {object_v,x}, #$6e

Return:
  rts
.endproc


.proc SpawnDirt
  jsr ObjectAllocate
  bcs Failure
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_DIRTY_SINK
  mov {object_life,x}, #$ff
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc DirtDispatch

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  mov player_injury, #30
  mov player_iframe, #100
  mov player_gravity, #$fe
  mov player_gravity_low, #$00
  dec player_health_delta
  dec player_health_delta
Next:
.endscope

  ; Draw position.
  mov draw_v, {object_v,x}
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  lda object_screen,x
  sbc camera_screen
  sta draw_screen
  bne Return

  ; Draw the dirty sink, left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  ldy draw_frame
  lda #DIRTY_KIND_TILE_LEFT
  sta sprite_tile,x
  lda #$03
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  ; Draw the dirty sink, right side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #DIRTY_KIND_TILE_RIGHT
  sta sprite_tile,x
  lda #$03
  sta sprite_attr,x

Return:
  rts
.endproc
