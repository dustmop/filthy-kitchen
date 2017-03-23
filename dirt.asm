.export DirtConstructor
.export DirtExecute
.export DirtDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.tiles.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "gunk_drop.h.asm"
.include "trash_gunk.h.asm"
.include "sound.h.asm"
.include "random.h.asm"
.include "move_trig.h.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp draw_screen, draw_h, draw_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta, player_just_landed
.importzp values

num_tiles = values + $00
tile_0 = values + $01
tile_1 = values + $02
tile_2 = values + $03
dirt_draw_attr = values + $04
dirt_draw_counter = values + $05

trash_orig_v = values + $00
trash_orig_h = values + $01
trash_orig_screen = values + $02
trash_gunk_dir = values + $04
trash_gunk_offset_h = values + $05
trash_gunk_offset_screen = values + $06

.import object_data_extend
dirt_kind = object_data_extend + $00
dirt_step = object_data_extend + $10
dirt_direction = dirt_step
dirt_h_low = object_data_extend + $20 ; only used by spit
dirt_v_low = object_data_extend + $30 ; only used by spit
dirt_shake = object_data_extend + $20 ; only used by trash


DIRT_KIND_SINK = 0
DIRT_KIND_SPLOTCH = 1
DIRT_KIND_PILE = 2
DIRT_KIND_PUDDLE = 3
DIRT_KIND_SPIT = 4
DIRT_KIND_TRASH = 5


DIRT_SPAWN_GUNK_DROP_BEGIN_PLUS_V = $72
DIRT_SPAWN_GUNK_DROP_LIMIT = 75
GUNK_DROP_LIFE = 65
TRASH_GUNK_LIFE = 65

.segment "CODE"


.proc DirtConstructor
  tya
  sta dirt_kind,x
  cmp #DIRT_KIND_SPLOTCH
  beq WallSplotch
  cmp #DIRT_KIND_SPIT
  beq Spit
  cmp #DIRT_KIND_TRASH
  beq Trash
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
Trash:
  mov {dirt_shake,x}, #0
  rts
.endproc


.proc DirtExecute

.scope MaybeSpit
  lda dirt_kind,x
  cmp #DIRT_KIND_SPIT
  jeq SpitHandler
.endscope

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope MaybeTrash
  lda dirt_kind,x
  cmp #DIRT_KIND_TRASH
  beq TrashHandler
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

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TrashHandler:

.scope ShakeTrashGunk
  lda dirt_shake,x
  beq Next
  dec dirt_shake,x
Next:
.endscope

.scope CollisionWithTrash
  jsr ObjectCollisionWithPlayer
  bcc Next
  bit player_just_landed
  bpl Next
  jsr TrashShakesAndSpitsGunk
Next:
.endscope

  jmp Draw

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpitHandler:

.scope SpitHandler
  jsr MovementTrig
  jsr MovementTrig
  lda object_v,x
  cmp #$f0
  blt Okay
DestroyIt:
  jsr ObjectFree
  clc
  rts
Okay:
.endscope

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
  cmp #DIRT_KIND_TRASH
  beq DirtyTrash
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
  jmp DrawIt
DirtyTrash:
  lda dirt_shake,x
  beq TrashNoShake
  lsr a
  lsr a
  tay
  lda shake_offset_v,y
TrashNoShake:
  clc
  adc draw_v
  clc
  adc #16
  sta draw_v
  lda draw_h
  clc
  adc #5
  sta draw_h
  bcs SkipTrash
  mov num_tiles, #2
  mov tile_0, #DIRTY_TRASH_TILE_0
  mov tile_1, #DIRTY_TRASH_TILE_1
  jmp DrawIt
SkipTrash:
  jmp Return

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



DirtDraw = DirtExecute::Draw



.proc TrashShakesAndSpitsGunk
  ; Player came down from a jump and landed on trash can.
  mov {dirt_shake,x}, #15

  lda #SFX_GLOOP
  jsr SoundPlay

  ; push x
  txa
  pha

  mov trash_orig_h, {object_h,x}
  mov trash_orig_v, {object_v,x}
  mov trash_orig_screen, {object_screen,x}

  mov trash_gunk_dir, #$ff
  mov trash_gunk_offset_h, #($100 - 18 + 4)
  mov trash_gunk_offset_screen, #$ff
  jsr CreateTrashGunk

  mov trash_gunk_dir, #$00
  mov trash_gunk_offset_h, #(18 + 6)
  mov trash_gunk_offset_screen, #$00
  jsr CreateTrashGunk

  ; pop x
  pla
  tax
Return:
  rts
.endproc


.proc CreateTrashGunk
  lda trash_orig_v
  clc
  adc #8
  sta draw_v
  lda trash_orig_h
  clc
  adc trash_gunk_offset_h
  sta draw_h
  lda trash_orig_screen
  adc trash_gunk_offset_screen
  sta draw_screen

  ; Allocate trash gunk
  jsr ObjectAllocate
  bcc Return
  jsr ObjectConstructor
  mov {object_kind,x}, #(OBJECT_KIND_TRASH_GUNK | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {trash_gunk_h_dir,x}, trash_gunk_dir
  mov {trash_gunk_h_low,x}, #$0
  mov {trash_gunk_v_speed_low,x}, #$0
  mov {trash_gunk_v_speed,x}, #$fd
  mov {object_life,x}, #TRASH_GUNK_LIFE

Return:
  rts
.endproc



shake_offset_v:
.byte 1
.byte 0
.byte 1
.byte 1

