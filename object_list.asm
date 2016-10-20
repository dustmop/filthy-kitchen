.export ObjectListInit
.export ObjectListUpdate
.export ObjectAllocate
.export ObjectFree
.export ObjectConstruct

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sprites.asm"
.include "include.const.asm"
.include "draw_picture.h.asm"

.importzp object_list_head, object_list_tail, camera_h
.importzp player_v, player_h, player_screen, player_has_swatter
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

.export object_data
object_data      = $440
object_kind      = object_data + $00
object_next      = object_data + $10
object_v         = object_data + $10
object_v_low     = object_data + $20
object_h         = object_data + $30
object_h_screen  = object_data + $40
object_frame     = object_data + $50
object_step      = object_data + $60
object_life      = object_data + $70
object_speed     = object_data + $80
object_speed_low = object_data + $90


OBJECT_KIND_NONE = $ff
OBJECT_KIND_SWATTER = $00

COLLIDE_PLAYER_SWATTER_V_HITBOX = 12
COLLIDE_PLAYER_SWATTER_H_HITBOX = 8
COLLIDE_PLAYER_SWATTER_V_OFFSET = 8
COLLIDE_PLAYER_SWATTER_H_OFFSET = 0

MAX_NUM_OBJECTS = 8


.segment "CODE"


.proc ObjectListInit
  ; Initialize a linked list in the object space. Each element has no object,
  ; and points to the next element in the list.
  ldx #0
Loop:
  mov {object_kind,x}, #OBJECT_KIND_NONE
  txa
  clc
  adc #1
  sta object_next,x
  inx
  cpx #MAX_NUM_OBJECTS
  bne Loop
Done:
  dex
  mov {object_next,x}, #$ff
  mov object_list_head, #$00
  mov object_list_tail, #$07
  rts
.endproc


.proc ObjectListUpdate
  ldx #0
Loop:
  lda object_kind,x
  bmi Increment
Body:
  jsr ObjectDispatch
  ; Step forward lifetime
  inc object_life,x
  beq IsImmortal
  lda object_life,x
  cmp lifetime
  blt Increment
  ; Destroy
  jsr ObjectFree
  jmp Increment
IsImmortal:
  mov {object_life,x}, #$ff
Increment:
  inx
  cpx #MAX_NUM_OBJECTS
  bne Loop
  rts
.endproc


.proc ObjectDispatch
  ; Retrieve info for the object.
  jsr ObjectRetrieveInfo
  mov draw_v, {object_v,x}

Movement:
  ; Move by adding speed.
  lda object_speed,x
  clc
  adc object_h,x
  sta object_h,x
  lda object_speed,x
  bmi MovingLeft
MovingRight:
  lda object_h_screen,x
  adc #0
  sta object_h_screen,x
  jmp DidMovement
MovingLeft:
  lda object_h_screen,x
  sbc #0
  sta object_h_screen,x
DidMovement:

.scope VerticalMovement
  lda object_v,x
  sec
  sbc #$08
  sec
  sbc player_v
  beq Next
  bge ObjectIsDown
ObjectIsAbove:
  lda object_v_low,x
  sec
  sbc #$80
  sta object_v_low,x
  bcs Next
  inc object_v,x
  jmp Next
ObjectIsDown:
  lda object_v_low,x
  clc
  adc #$80
  sta object_v_low,x
  bcc Next
  dec object_v,x
Next:
.endscope

  ; Draw position.
  lda object_h,x
  sec
  sbc camera_h
  sta draw_h

  ; Get deltas.
  lda object_v,x
  sec
  sbc player_v
  sta delta_v
  lda object_h,x
  sec
  sbc player_h
  sta delta_h
  lda object_h_screen,x
  sbc player_screen
  sta delta_screen

  ; Maybe collide with player.
.scope CollideWithPlayer
  lda delta_h
  sec
  sbc #COLLIDE_PLAYER_SWATTER_H_OFFSET
  bpl AbsoluteH
  eor #$ff
  clc
  adc #1
AbsoluteH:
  cmp #COLLIDE_PLAYER_SWATTER_H_HITBOX
  bge Next
  lda delta_v
  sec
  sbc #COLLIDE_PLAYER_SWATTER_V_OFFSET
  bpl AbsoluteV
  eor #$ff
  clc
  adc #1
AbsoluteV:
  cmp #COLLIDE_PLAYER_SWATTER_V_HITBOX
  bge Next
  ; Collided.
  mov player_has_swatter, #1
  jsr ObjectFree
  jmp Return
Next:
.endscope

.scope Accelerate
  ; Screen = $00 if swatter is to the right of the player.
  ; Screen = $ff if swatter is to the left of the player.
  lda delta_screen
  beq ObjectToTheRight
ObjectToTheLeft:
  ; If far enough away from player, accelerate at full rate.
  lda delta_h
  cmp #$e0
  blt FullRateFromLeft
  ; If speed is already pointed to the right, accelerate at full rate.
  lda object_speed,x
  bpl FullRateFromLeft
  ; Otherwise, accelerate at partial rate.
  jmp PartialRateFromLeft
FullRateFromLeft:
  lda #($100 - $40)
  jmp AccelerateFromLeft
PartialRateFromLeft:
  lda #($100 - $10)
AccelerateFromLeft:
  clc
  adc object_speed_low,x
  sta object_speed_low,x
  bcs Next
  inc object_speed,x
  jmp Next
ObjectToTheRight:
  ; If far enough away from player, accelerate at full rate.
  lda delta_h
  cmp #$20
  bge FullRateFromRight
  ; If speed is already pointed to the left, accelerate at full rate.
  lda object_speed,x
  bmi FullRateFromRight
  ; Otherwise, accelerate at partial rate.
  jmp PartialRateFromRight
FullRateFromRight:
  lda #$40
  jmp AccelerateFromRight
PartialRateFromRight:
  lda #$10
AccelerateFromRight:
  clc
  adc object_speed_low,x
  sta object_speed_low,x
  bcc Next
  dec object_speed,x
Next:
.endscope

.scope MaximumSpeed
  ; Clamp
  lda object_speed,x
  bmi Negative
Positive:
  cmp #SWATTER_SPEED
  blt Okay
  mov {object_speed,x}, #SWATTER_SPEED
  jmp Okay
Negative:
  cmp #($100 - SWATTER_SPEED)
  bge Okay
  mov {object_speed,x}, #($100 - SWATTER_SPEED)
Okay:
.endscope

  ; Animation.
.scope StepAnimation
  inc object_step,x
  lda object_step,x
  cmp animate_limit
  blt Next
  mov {object_step,x}, #0
  inc object_frame,x
  lda object_frame,x
  cmp num_frames
  blt Next
  mov {object_frame,x}, #0
Next:
.endscope
  ldy object_frame,x
  lda swatter_animation_sequence,y
  sta draw_picture_id
  MovWord draw_picture_pointer, swatter_picture_data
  MovWord draw_sprite_pointer, swatter_sprite_data
  mov draw_palette, #0
  ; Draw the sprites.
  jsr DrawPicture
Return:
  rts
.endproc


.proc ObjectRetrieveInfo
  ; push X
  txa
  pha
  lda object_kind,x
  tax
  ; Get values for the object from the tables below.
  mov speed, {table_object_speed,x}
  mov lifetime, {table_object_lifetime,x}
  mov num_frames, {table_object_num_frames,x}
  mov animate_limit, {table_object_animate_limit,x}
  pla
  tax
  rts
.endproc


swatter_animation_sequence:
.byte $06,$03,$00,$13,$11,$0e,$0b,$08


.proc ObjectAllocate
  ; Check if the list has only one element.
  ldx object_list_head
  cpx object_list_tail
  beq AssignEmptyList
  ; Check if the list is totally empty. If so, fail to allocate.
  cpx #$ff
  beq Done
  ; Update header pointer to point to the next element.
  mov object_list_head, {object_next,x}
  ; Set allocated element's next to point to null.
  ; Somewhat unecessary, but nice for visual debugging.
  mov {object_next,x}, #$ff
  bne Done
AssignEmptyList:
  ; Allocate the last element from the list.
  mov object_list_head, #$ff
  mov object_list_tail, _
Done:
  rts
.endproc


.proc ObjectConstruct
  lda #0
  sta object_frame,x
  sta object_step,x
  sta object_life,x
  sta object_speed,x
  sta object_speed_low,x
  rts
.endproc


.proc ObjectFree
  ; Check if the list was totally empty.
  lda object_list_head
  cmp #$ff
  beq IsEmptyList
  ; Link onto the old tail element.
  ldy object_list_tail
  txa
  sta object_next,y
  ; Invalidate kind
  lda #OBJECT_KIND_NONE
  sta object_kind,x
  ; Update the tail pointer.
  stx object_list_tail
  ; Clear next
  sta object_next,x
  bne Done
IsEmptyList:
  ; List now has exactly one element.
  stx object_list_head
  stx object_list_tail
  mov {object_next,x}, #$ff
Done:
  rts
.endproc



table_object_num_frames:
.byte 8

table_object_animate_limit:
.byte 2

table_object_lifetime:
.byte 20

table_object_speed:
.byte 5


