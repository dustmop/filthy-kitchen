.export UtensilsMaybeCreate
.export UtensilsDispatch

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp have_spawned_utensils
.importzp draw_screen, draw_h, draw_v
.importzp player_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta
.importzp values

.import object_data_extend


UTENSILS_TILE_LEFT = $83
UTENSILS_TILE_RIGHT = $85


.segment "CODE"


.proc UtensilsMaybeCreate
MaybeSpawnUtensils:
  lda camera_h
  cmp #$f0
  blt Return
SpawnUtensils:
  lda #0
  jsr CreateOnce
Return:
  rts
.endproc


.proc CreateOnce
  cmp have_spawned_utensils
  bne Return

  cmp #0
  beq DoSpawn
  bne Return

DoSpawn:
  jsr SpawnUtensils
  bcc Return
  inc have_spawned_utensils

  lda player_v
  cmp #$60
  bge SpawnLowerLevel

SpawnHigherLevel:
  mov {object_v,x}, #$58
  jmp Okay

SpawnLowerLevel:
  mov {object_v,x}, #$a8

Okay:
  mov {object_screen,x}, #$01
  mov {object_h,x}, #$f7


Return:
  rts
.endproc


.proc SpawnUtensils
  jsr ObjectAllocate
  bcs Failure
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_UTENSILS
  mov {object_life,x}, #$ff
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc UtensilsDispatch

  lda object_h,x
  sec
  sbc #2
  sta object_h,x
  lda object_screen,x
  sbc #0
  sta object_screen,x
  bpl Okay
  jsr ObjectFree
  jmp Return
Okay:

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

  ; Draw the utensils, left side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  ldy draw_frame
  lda #UTENSILS_TILE_LEFT
  sta sprite_tile,x
  lda #$03
  sta sprite_attr,x

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  ; Draw the utensils, right side.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #UTENSILS_TILE_RIGHT
  sta sprite_tile,x
  lda #$03
  sta sprite_attr,x

Return:
  rts
.endproc
