.export ObjectListInit
.export ObjectListUpdate
.export ObjectAllocate
.export ObjectFree
.export ObjectConstruct

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sprites.asm"
.include "swatter.h.asm"
.include "fly.h.asm"

.importzp object_list_head, object_list_tail, camera_h
.importzp player_v, player_h, player_screen, player_has_swatter
.importzp player_collision_idx
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
OBJECT_KIND_FLY = $01

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
  ; Dispatch upon kind
  lda object_kind,x
  beq DispatchSwatter
  cmp #OBJECT_KIND_FLY
  beq DispatchFly
  bne Done
DispatchSwatter:
  jsr SwatterDispatch
  jmp Done
DispatchFly:
  jsr FlyDispatch
Done:
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

