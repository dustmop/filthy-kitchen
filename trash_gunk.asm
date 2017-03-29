.export TrashGunkExecute
.export TrashGunkDraw
.export TrashGunkSpawnTwoInOppositeDirections
.export trash_gunk_h_dir_and_invul
.export trash_gunk_h_low
.export trash_gunk_v_speed_low
.export trash_gunk_v_speed

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "include.tiles.asm"
.include "object_list.h.asm"
.include "sploosh.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "sound.h.asm"
.include "hurt_player.h.asm"

.importzp camera_h, camera_screen
.importzp player_health_delta
.importzp draw_screen, draw_h, draw_v, draw_frame
.importzp player_v
.importzp player_iframe
.importzp gloop_sfx
.importzp values

gunk_tile = values + $00
gunk_attr = values + $01
spawn_gunk_dir_and_invul = values + $04
spawn_gunk_offset_h      = values + $05
spawn_gunk_offset_screen = values + $06
spawn_orig_v = values + $07
spawn_orig_h = values + $08
spawn_orig_screen = values + $09

.import object_data_extend
trash_gunk_h_dir_and_invul = object_data_extend + $00
trash_gunk_h_low           = object_data_extend + $10
trash_gunk_v_speed         = object_data_extend + $20
trash_gunk_v_speed_low     = object_data_extend + $30


SPLOOSH_V = $ba

SPEED_V_LOW = $38
SPEED_H_LOW = $f0

TRASH_GUNK_LIFE = 65


.segment "CODE"


.proc TrashGunkExecute

.scope Movement
  ; Vertical
  lda trash_gunk_v_speed_low,x
  clc
  adc #SPEED_V_LOW
  sta trash_gunk_v_speed_low,x
  lda trash_gunk_v_speed,x
  adc #0
  sta trash_gunk_v_speed,x
  clc
  adc object_v,x
  sta object_v,x
  ; Horizontal
  lda trash_gunk_h_dir_and_invul,x
  bpl MoveRight
MoveLeft:
  lda trash_gunk_h_low,x
  sec
  sbc #SPEED_H_LOW
  sta trash_gunk_h_low,x
  lda object_h,x
  sbc #$0
  sta object_h,x
  jmp Next
MoveRight:
  lda trash_gunk_h_low,x
  clc
  adc #SPEED_H_LOW
  sta trash_gunk_h_low,x
  lda object_h,x
  adc #$0
  sta object_h,x
  jmp Next
Next:
.endscope

AfterMovement:

.scope CollisionWithBackground
  lda object_v,x
  cmp #SPLOOSH_V
  blt Next
  ; sploosh
  mov draw_v, #SPLOOSH_V
  lda object_h,x
  sec
  sbc #4
  sta draw_h
  lda object_screen,x
  sbc #0
  sta draw_screen
  jsr ObjectFree
  jsr ObjectAllocate
  bcc Next
  mov {object_kind,x}, #(OBJECT_KIND_SPLOOSH | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {object_life,x}, #15
  mov {object_step,x}, #0
  mov {object_frame,x}, _
  mov draw_frame, #0
  jsr SplooshExecute
  rts
Next:
.endscope

.scope CollisionWithPlayer
  ; Check invulnerable flag.
  lda trash_gunk_h_dir_and_invul,x
  lsr a
  bcc RegularCheck
  ; If invul flag set, first animation frame doesn't cause player collisions.
  lda trash_gunk_v_speed,x
  bmi Next
RegularCheck:
  ; Check collision like normal.
  lda player_iframe
  bne Next
  jsr ObjectCollisionWithPlayer
  bcc Next
DidCollide:
  ldy #1
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
  bne Return

  ; Init tile
  mov gunk_attr, #3
  ; Tile
  lda trash_gunk_v_speed,x
  bmi DrawMovingUp
  beq DrawGlob
  cmp #3
  blt DrawMovingDown
DrawMovingDownFast:
  mov gunk_tile, #TRASH_GUNK_TILE_3
  bne DrawHaveTile
DrawMovingDown:
  mov gunk_tile, #TRASH_GUNK_TILE_2
  bne DrawHaveTile
DrawGlob:
  mov gunk_tile, #TRASH_GUNK_TILE_1
  bne DrawHaveTile
DrawMovingUp:
  mov gunk_tile, #TRASH_GUNK_TILE_0
  mov gunk_attr, #$83
DrawHaveTile:
  ; Attr
  lda trash_gunk_h_dir_and_invul,x
  bpl DrawHaveAttr
  lda gunk_attr
  eor #$40
  sta gunk_attr
DrawHaveAttr:

  ; Draw the gunk
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda gunk_tile
  sta sprite_tile,x
  lda gunk_attr
  sta sprite_attr,x

Return:
  rts
.endproc


TrashGunkDraw = TrashGunkExecute::Draw


trash_gunk_frames:
.byte TRASH_GUNK_TILE_0
.byte TRASH_GUNK_TILE_1
.byte TRASH_GUNK_TILE_2
.byte TRASH_GUNK_TILE_3



.proc TrashGunkSpawnTwoInOppositeDirections
  lda #SFX_GLOOP
  jsr SoundPlay

  ; push x
  txa
  pha

  mov spawn_orig_h, {object_h,x}
  mov spawn_orig_v, {object_v,x}
  mov spawn_orig_screen, {object_screen,x}

  tya
  eor #$80
  sta spawn_gunk_dir_and_invul
  mov spawn_gunk_offset_h, #($100 - 18 + 4 + 5)
  mov spawn_gunk_offset_screen, #$ff
  jsr CreateSingleTrashGunk

  lda spawn_gunk_dir_and_invul
  eor #$80
  sta spawn_gunk_dir_and_invul
  mov spawn_gunk_offset_h, #(18 + 6 - 5)
  mov spawn_gunk_offset_screen, #$00
  jsr CreateSingleTrashGunk

  ; pop x
  pla
  tax
Return:
  rts
.endproc


.proc CreateSingleTrashGunk
  lda spawn_orig_v
  clc
  adc #8
  sta draw_v
  lda spawn_orig_h
  clc
  adc spawn_gunk_offset_h
  sta draw_h
  lda spawn_orig_screen
  adc spawn_gunk_offset_screen
  sta draw_screen

  ; Allocate trash gunk
  jsr ObjectAllocate
  bcc Return
  jsr ObjectConstructor
  mov {object_kind,x}, #(OBJECT_KIND_TRASH_GUNK | OBJECT_IS_NEW)
  mov {object_v,x}, draw_v
  mov {object_h,x}, draw_h
  mov {object_screen,x}, draw_screen
  mov {trash_gunk_h_dir_and_invul,x}, spawn_gunk_dir_and_invul
  mov {trash_gunk_h_low,x}, #$0
  mov {trash_gunk_v_speed_low,x}, #$0
  mov {trash_gunk_v_speed,x}, #$fd
  mov {object_life,x}, #TRASH_GUNK_LIFE

Return:
  rts
.endproc
