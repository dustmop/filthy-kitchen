.export ToasterConstructor
.export ToasterExecute
.export ToasterDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sprites.asm"
.include "object_list.h.asm"
.include "sprite_space.h.asm"
.include "shared_object_values.asm"
.include "draw_picture.h.asm"
.include "sound.h.asm"

.importzp camera_h, camera_screen
.importzp draw_screen, draw_h, draw_v, draw_frame
.importzp player_v
.importzp player_injury, player_iframe, player_gravity
.importzp player_gravity_low, player_health_delta
.importzp elec_sfx
.importzp values

.import object_data_extend
toaster_jump     = object_data_extend + $00
toaster_jump_low = object_data_extend + $10
toaster_orig_v   = object_data_extend + $20
toaster_in_air   = object_data_extend + $30
;toaster_speed     = object_data_extend + $20
;toaster_speed_low = object_data_extend + $30


.segment "CODE"


.proc ToasterConstructor
  mov {object_life,x}, #$f0
  mov {toaster_in_air,x}, #0
  mov {toaster_orig_v,x}, {object_v,x}
  rts
.endproc


.proc ToasterExecute

  mov elec_sfx, #0

.scope MaybeDespawn
  jsr ObjectOffscreenDespawn
  bcc Okay
  rts
Okay:
.endscope

.scope CountDown
  lda object_life,x
  cmp #$b0
  bge Next
  ; Jump the toaster.
  mov {object_life,x}, #$f0
  mov {toaster_in_air,x}, #$ff
  mov {toaster_jump,x}, #$fd
  mov {toaster_jump_low,x}, #$00
  mov elec_sfx, #$ff
Next:
.endscope

.scope Movement
  lda toaster_in_air,x
  beq Next
  ;
  lda toaster_jump,x
  clc
  adc object_v,x
  sta object_v,x
  lda toaster_jump_low,x
  clc
  adc #$40
  sta toaster_jump_low,x
  lda toaster_jump,x
  adc #0
  sta toaster_jump,x
  ;
  lda object_v,x
  cmp toaster_orig_v,x
  blt Next
EndJump:
  mov {toaster_in_air,x}, #0
  mov {object_v,x}, {toaster_orig_v,x}
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

  lda toaster_in_air,x
  beq DrawSit
DrawInAir:
  ldy draw_frame
  lda toaster_jump_animation,y
  sta draw_picture_id
  jmp DrawReady
DrawSit:
  lda #PICTURE_ID_TOASTER_SIT
  sta draw_picture_id
DrawReady:
  MovWord draw_picture_pointer, toaster_picture_data
  MovWord draw_sprite_pointer, toaster_sprite_data
  mov draw_palette, #3
  jsr DrawPicture

  lda elec_sfx
  bpl Return
  ; Play sound effect of electricity.
  lda #SFX_ELECTRIC
  jsr SoundPlay

Return:
  rts
.endproc


ToasterDraw = ToasterExecute::Draw


toaster_jump_animation:
.byte PICTURE_ID_TOASTER_JUMP0_LEFT
.byte PICTURE_ID_TOASTER_JUMP1_LEFT
.byte PICTURE_ID_TOASTER_JUMP2_LEFT
.byte PICTURE_ID_TOASTER_JUMP0_RIGHT
.byte PICTURE_ID_TOASTER_JUMP1_RIGHT
.byte PICTURE_ID_TOASTER_JUMP2_RIGHT

; TODO: Pictures can't correctly process toaster.
PICTURE_ID_TOASTER_SIT = 0
PICTURE_ID_TOASTER_JUMP0_LEFT = 3
PICTURE_ID_TOASTER_JUMP1_LEFT = 6
PICTURE_ID_TOASTER_JUMP2_LEFT = 11
PICTURE_ID_TOASTER_JUMP0_RIGHT = 16
PICTURE_ID_TOASTER_JUMP1_RIGHT = 19
PICTURE_ID_TOASTER_JUMP2_RIGHT = 24

toaster_picture_data:
.byte $00,$01,$ff ; 0
.byte $02,$03,$ff ; 3
.byte $04,$05,$06,$07,$ff ; 6
.byte $08,$09,$0a,$0b,$ff ; 11
.byte $43,$42,$ff ; 16
.byte $45,$44,$47,$46,$ff ; 19
.byte $49,$48,$4b,$4a,$ff ; 24

toaster_sprite_data:
;       y,  x,    tile
;$00,$01
.byte $10,$00    ,TOASTER_SIT_TILE
.byte $10,$08-$08,TOASTER_SIT_TILE+2
;$02,$03
.byte $10,$00    ,TOASTER_JUMP0_TILE
.byte $10,$08-$08,TOASTER_JUMP0_TILE+2
;$04,$05,$06,$07
.byte $00,$00         ,ELEC_JUMP1_TILE
.byte $00,$08-$08     ,ELEC_JUMP1_TILE+2
.byte $10,$00-$10+$100,TOASTER_JUMP1_TILE
.byte $10,$08-$18+$100,TOASTER_JUMP1_TILE+2
;$08,$09,$0a,$0b
.byte $00,$00         ,ELEC_JUMP2_TILE
.byte $00,$08-$08     ,ELEC_JUMP2_TILE+2
.byte $10,$00-$10+$100,TOASTER_JUMP2_TILE
.byte $10,$08-$18+$100,TOASTER_JUMP2_TILE+2


TOASTER_SIT_TILE = $b3
TOASTER_JUMP0_TILE = $bf

TOASTER_JUMP1_TILE = $c3
ELEC_JUMP1_TILE = $b7

TOASTER_JUMP2_TILE = $c7
ELEC_JUMP2_TILE = $bb
