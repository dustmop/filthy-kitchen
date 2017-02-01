.export DirtConstructor
.export DirtExecute

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "gunk_drop.h.asm"
.include "sound.h.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp draw_screen, draw_h, draw_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta
.importzp values

num_tiles = values + $00
tile_0 = values + $01
tile_1 = values + $02
tile_2 = values + $03

.import object_data_extend
dirt_kind = object_data_extend + $00
dirt_step = object_data_extend + $10


DIRT_KIND_SINK = 0
DIRT_KIND_SPLOTCH = 1
DIRT_KIND_PILE = 2
DIRT_KIND_PUDDLE = 3


DIRTY_SINK_TILE_0 = $89
DIRTY_SINK_TILE_1 = $8b

DIRTY_PILE_TILE_0 = $97
DIRTY_PILE_TILE_1 = $99
DIRTY_PILE_TILE_2 = $9b

DIRT_SPAWN_GUNK_DROP_BEGIN_PLUS_V = $72
DIRT_SPAWN_GUNK_DROP_LIMIT = 75
GUNK_DROP_LIFE = 65

.segment "CODE"


.proc DirtConstructor
  tya
  sta dirt_kind,x
  cmp #DIRT_KIND_SPLOTCH
  bne Return
WallSplotch:
  lda #DIRT_SPAWN_GUNK_DROP_BEGIN_PLUS_V
  sec
  sbc object_v,x
  sta dirt_step,x
Return:
  rts
.endproc


.proc DirtExecute

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope SpawnGunkDrop
  lda dirt_kind,x
  cmp #DIRT_KIND_SPLOTCH
  bne Next
  ; Spot on the wall can spawn gunk.
  inc dirt_step,x
  lda dirt_step,x
  cmp #DIRT_SPAWN_GUNK_DROP_LIMIT
  blt Next
  mov {dirt_step,x}, #0
  ;
  lda object_v,x
  clc
  adc #9
  sta draw_v
  lda object_h,x
  clc
  adc #5
  sta draw_h
  lda object_screen,x
  adc #0
  sta draw_screen
  ; push x
  txa
  pha
  ; Allocate gunk.
  jsr ObjectAllocate
  bcc Return
  jsr ObjectConstructor
  mov {object_kind,x}, #OBJECT_KIND_GUNK_DROP
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {gunk_drop_form,x}, #0
  mov {gunk_drop_inc,x}, _
  mov {gunk_drop_speed_low,x}, _
  mov {gunk_drop_speed,x}, _
  mov {object_life,x}, #GUNK_DROP_LIFE
Return:
  ; pop X
  pla
  tax
Next:
.endscope

.scope CollisionWithPlayer
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  lda #SFX_GOT_HURT
  jsr SoundPlay
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

  lda dirt_kind,x
  cmp #DIRT_KIND_SINK
  beq DirtySink
  cmp #DIRT_KIND_PILE
  beq DirtyPile
  rts

DirtySink:
  lda draw_v
  clc
  adc #4
  sta draw_v
  mov num_tiles, #2
  mov tile_0, #DIRTY_SINK_TILE_0
  mov tile_1, #DIRTY_SINK_TILE_1
  jmp DrawIt
DirtyPile:
  lda draw_h
  sec
  sbc #3
  sta draw_h
  mov num_tiles, #3
  mov tile_0, #DIRTY_PILE_TILE_0
  mov tile_1, #DIRTY_PILE_TILE_1
  mov tile_2, #DIRTY_PILE_TILE_2

DrawIt:
  ldy #0
DrawLoop:
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda tile_0,y
  sta sprite_tile,x
  lda #$03
  sta sprite_attr,x

  dec num_tiles
  beq Return

  iny

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  jmp DrawLoop

Return:
  rts
.endproc
