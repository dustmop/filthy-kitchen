.export DirtConstructor
.export DirtExecute
.export DirtDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "gunk_drop.h.asm"
.include "sound.h.asm"
.include "random.h.asm"

.import trig_movement
.import trig_lookup
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
dirt_draw_attr = values + $04
dirt_draw_counter = values + $05

.import object_data_extend
dirt_kind = object_data_extend + $00
dirt_step = object_data_extend + $10
dirt_direction = dirt_step
dirt_h_low = object_data_extend + $20
dirt_v_low = object_data_extend + $30


DIRT_KIND_SINK = 0
DIRT_KIND_SPLOTCH = 1
DIRT_KIND_PILE = 2
DIRT_KIND_PUDDLE = 3
DIRT_KIND_SPIT = 4


DIRTY_SINK_TILE_0 = $89
DIRTY_SINK_TILE_1 = $8b

DIRTY_PILE_TILE_0 = $9d
DIRTY_PILE_TILE_1 = $9f

DIRTY_SPIT_TILE_0 = $cf
DIRTY_SPIT_TILE_1 = $d1


DIRT_SPAWN_GUNK_DROP_BEGIN_PLUS_V = $72
DIRT_SPAWN_GUNK_DROP_LIMIT = 75
GUNK_DROP_LIFE = 65

.segment "CODE"


.proc DirtConstructor
  tya
  sta dirt_kind,x
  cmp #DIRT_KIND_SPLOTCH
  beq WallSplotch
  cmp #DIRT_KIND_SPIT
  beq Spit
  rts
WallSplotch:
  lda #DIRT_SPAWN_GUNK_DROP_BEGIN_PLUS_V
  sec
  sbc object_v,x
  sta dirt_step,x
  rts
Spit:
  jsr RandomGet
  and #$07
  clc
  adc #36
  sta dirt_direction,x
  rts
.endproc


.proc DirtExecute

  lda dirt_kind,x
  cmp #DIRT_KIND_SPIT
  beq SpitHandler

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

  jmp Later

SpitHandler:
.scope SpitHandler
  jsr ApplyMovement
  jsr ApplyMovement
.endscope

Later:

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


Draw:
  mov dirt_draw_attr, #$03
  mov dirt_draw_counter, #$00

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

  lda dirt_kind,x
  cmp #DIRT_KIND_SINK
  beq DirtySink
  cmp #DIRT_KIND_PILE
  beq DirtyPile
  cmp #DIRT_KIND_SPIT
  beq DirtySpit
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
  mov tile_2, #DIRTY_PILE_TILE_0
  mov dirt_draw_counter, #$81
  jmp DrawIt
DirtySpit:
  lda draw_h
  sec
  sbc #3
  sta draw_h
  mov num_tiles, #2
  mov tile_0, #DIRTY_SPIT_TILE_0
  mov tile_1, #DIRTY_SPIT_TILE_1

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
  lda dirt_draw_attr
  sta sprite_attr,x

  dec num_tiles
  beq Return

  iny

  bit dirt_draw_counter
  bpl :+
  dec dirt_draw_counter
  bmi :+
  ;
  lda dirt_draw_attr
  ora #$40
  sta dirt_draw_attr
  dec draw_h
:

  lda draw_h
  clc
  adc #8
  sta draw_h
  bcs Return

  jmp DrawLoop

Return:
  rts
.endproc


.proc ApplyMovement
  ldy dirt_direction,x
  lda trig_lookup,y
  tay
HorizontalDelta:
  lda trig_movement,y
  clc
  adc dirt_h_low,x
  sta dirt_h_low,x
  iny
  lda trig_movement,y
  bmi ToTheLeft
ToTheRight:
  adc object_h,x
  sta object_h,x
  lda object_screen,x
  adc #0
  sta object_screen,x
  jmp VerticalDelta
ToTheLeft:
  adc object_h,x
  sta object_h,x
  lda object_screen,x
  adc #$ff
  sta object_screen,x
VerticalDelta:
  iny
  lda trig_movement,y
  clc
  adc dirt_v_low,x
  sta dirt_v_low,x
  iny
  lda trig_movement,y
  adc object_v,x
  sta object_v,x
  cmp #$f0
  bge Failure
  blt Success
Failure:
  jsr ObjectFree
  clc
  rts
Success:
  sec
  rts
.endproc


DirtDraw = DirtExecute::Draw
