.export FlyListUpdate
.export FlyDispatch

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"

.importzp player_screen, player_h, camera_h
.importzp spawn_count
.importzp draw_h, draw_v

.importzp values

;DrawPicture    values + $00
speed         = values + $01
lifetime      = values + $02
animate_limit = values + $03
num_frames    = values + $04
flip_bits     = values + $05
delta_h       = values + $06
delta_v       = values + $07
delta_screen  = values + $08
collide_dist  = values + $09

.segment "CODE"

.proc FlyListUpdate
  inc spawn_count
  lda spawn_count
  cmp #100
  blt Return
  mov spawn_count, #0

  jsr ObjectAllocate
  bcs Return
  jsr ObjectConstruct
  mov {object_kind,x}, #OBJECT_KIND_FLY
  mov {object_h_screen,x}, player_screen
  mov {object_life,x}, #$ff

  lda player_h
  clc
  adc #$60
  sta object_h,x
  mov {object_v,x}, #$80

Return:
  rts
.endproc


FLY_ANIMATE_1 = $0b
FLY_ANIMATE_2 = $0d
FLY_ANIMATE_3 = $0f


.proc FlyDispatch
  txa
  pha

  ; Draw position.
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h
  mov draw_v, {object_v,x}

  ; Draw the fly.
  jsr SpriteSpaceAllocate
  lda draw_v
  sta sprite_v,x
  lda draw_h
  sta sprite_h,x
  lda #FLY_ANIMATE_1
  sta sprite_tile,x
  lda #2
  sta sprite_attr,x

  pla
  tax
  rts
.endproc
