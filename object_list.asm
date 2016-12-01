.export ObjectListInit
.export ObjectListUpdate
.export ObjectListCountAvail
.export ObjectAllocate
.export ObjectFree
.export ObjectConstruct
.export ObjectCollisionWithPlayer
.export ObjectMovementApplyDelta

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sprites.asm"
.include "swatter.h.asm"
.include "fly.h.asm"
.include "explode.h.asm"
.include "points.h.asm"
.include "food.h.asm"
.include "shared_object_values.asm"
.include "collision_data.h.asm"


.importzp object_list_head, object_list_tail, camera_h
.importzp player_v, player_h, player_screen, player_collision_idx
.importzp values

.export object_data
object_data   = $440
object_kind   = object_data + $00
object_next   = object_data + $10
object_v      = object_data + $10
object_h      = object_data + $20
object_screen = object_data + $30
object_frame  = object_data + $40
object_step   = object_data + $50
object_life   = object_data + $60
.export object_data_extend
object_data_extend = object_data + $70


OBJECT_KIND_NONE = $ff
OBJECT_KIND_SWATTER = $00
OBJECT_KIND_FLY     = $01
OBJECT_KIND_EXPLODE = $02
OBJECT_KIND_POINTS  = $03
OBJECT_KIND_FOOD    = $04

OBJECT_IS_NEW = $40
OBJECT_CLEAR_NEW = $3f

MAX_NUM_OBJECTS = 10


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
  mov object_list_tail, #(MAX_NUM_OBJECTS - 1)
  rts
.endproc


.proc ObjectListCountAvail
  ldy #MAX_NUM_OBJECTS
  ldx #0
Loop:
  lda object_kind,x
  bmi Increment
  dey
Increment:
  inx
  cpx #MAX_NUM_OBJECTS
  bne Loop
  tya
  rts
.endproc


.proc ObjectListUpdate
  ldx #0
Loop:
  lda object_kind,x
  bmi Increment
  cmp #OBJECT_IS_NEW
  bge Increment
Body:
  jsr ObjectDispatch
  ; Step forward lifetime
  lda object_life,x
  cmp #$ff
  ; Is immortal
  beq Increment
  dec object_life,x
  bne Increment
  ; Destroy
  jsr ObjectFree
  jmp Increment
IsImmortal:
  mov {object_life,x}, #$ff
Increment:
  inx
  cpx #MAX_NUM_OBJECTS
  bne Loop
  ; Clear "new" bit from objects
ClearLoop:
  lda object_kind,x
  bmi ClearDecrement
  cmp #OBJECT_IS_NEW
  blt ClearDecrement
  and #OBJECT_CLEAR_NEW
  sta object_kind,x
ClearDecrement:
  dex
  bpl ClearLoop
  rts
.endproc


.proc ObjectDispatch
  lda object_kind,x
  tay
  ; Retrieve info for the object.
  mov animate_limit, {table_object_animate_limit,y}
  mov num_frames,    {table_object_num_frames,y}
  ; Animation
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
  mov draw_frame, {object_frame,x}
  ; Movement, based upon kind
  txa
  pha
  tya
  beq DispatchSwatter
  cmp #OBJECT_KIND_FLY
  beq DispatchFly
  cmp #OBJECT_KIND_EXPLODE
  beq DispatchExplode
  cmp #OBJECT_KIND_POINTS
  beq DispatchPoints
  cmp #OBJECT_KIND_FOOD
  beq DispatchFood
  bne DispatchDone
DispatchSwatter:
  jsr SwatterDispatch
  jmp DispatchDone
DispatchFly:
  jsr FlyDispatch
  jmp DispatchDone
DispatchExplode:
  jsr ExplodeDispatch
  jmp DispatchDone
DispatchPoints:
  jsr PointsDispatch
  jmp DispatchDone
DispatchFood:
  jsr FoodDispatch
DispatchDone:
  pla
  tax
Return:
  rts
.endproc


.proc ObjectMovementApplyDelta
  ; Vertical
  lda delta_v
  clc
  adc object_v,x
  sta object_v,x
  ; Horizontal
  lda delta_h
  clc
  adc object_h,x
  sta object_h,x
  lda delta_h
  bmi MovementLeft
MovementRight:
  lda object_screen,x
  adc #0
  sta object_screen,x
  jmp MovementDone
MovementLeft:
  lda object_screen,x
  sbc #0
  sta object_screen,x
MovementDone:
  rts
.endproc


.proc ObjectCollisionWithPlayer
  ; Calculate deltas from player.
  lda object_v,x
  sec
  sbc player_v
  sta delta_v
  lda object_h,x
  sec
  sbc player_h
  sta delta_h
  lda object_screen,x
  sbc player_screen
  sta delta_screen
  ; Check that screen is 0 or -1.
  beq Okay
  cmp #$ff
  bne Failure
Okay:
  ; Check that screen and h have the same sign bit.
  eor delta_h
  and #$80
  bne Failure

  ; Maybe collide with player.
  ldy player_collision_idx
  lda delta_h
  sec
  sbc collision_data_player,y ; h_offset
  bpl AbsoluteH
  eor #$ff
  clc
  adc #1
AbsoluteH:
  iny
  cmp collision_data_player,y ; h_hitbox
  bge Failure
  lda delta_v
  sec
  iny
  sbc collision_data_player,y ; v_offset
  bpl AbsoluteV
  eor #$ff
  clc
  adc #1
AbsoluteV:
  iny
  cmp collision_data_player,y ; v_hitbox
  bge Failure
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc ObjectAllocate
  ; Check if the list is totally empty. If so, fail to allocate.
  ldx object_list_head
  cpx #$ff
  beq Failure
  ; Check if the list has only one element.
  cpx object_list_tail
  beq AssignEmptyList
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
  clc
  rts
Failure:
  sec
  rts
.endproc


.proc ObjectConstruct
  lda #0
  sta object_frame,x
  sta object_step,x
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
  mov {object_kind,x}, #OBJECT_KIND_NONE
Done:
  rts
.endproc



table_object_num_frames:
.byte 8, 3, 3, 1, 8

table_object_animate_limit:
.byte 2, 3, 6, 1, 4
