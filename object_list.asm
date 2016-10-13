.export ObjectListInit
.export ObjectListUpdate
.export ObjectAllocate
.export ObjectFree

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sprites.asm"

.importzp object_list_head, object_list_tail, camera_h
.importzp values

pos_v    = values + $00
pos_h    = values + $01
speed    = values + $02
lifetime = values + $03


.export object_data
object_data  = $440
object_kind  = object_data + $00
object_next  = object_data + $10
object_pos_v = object_data + $10
object_pos_h = object_data + $20
object_dir   = object_data + $30
object_frame = object_data + $40
object_step  = object_data + $50


OBJECT_KIND_NONE = $ff
OBJECT_KIND_SWATTER = $00

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
  jsr ObjectListErase
  ldx #0
Loop:
  lda object_kind,x
  bmi Increment
Body:
  jsr ObjectAction
  ; TODO: Direction
  ; Move forward
  lda object_pos_h,x
  clc
  adc speed
  sta object_pos_h,x
  ; Draw the sprites.
  jsr ObjectDraw
  ; Step forward lifetime
  inc object_step,x
  lda object_step,x
  cmp lifetime
  blt Increment
  ; Destroy
  jsr ObjectFree
Increment:
  inx
  cpx #MAX_NUM_OBJECTS
  bne Loop
  rts
.endproc


.proc ObjectListErase
  ; Erase all of the sprites in shadow OAM.
  lda #$ff
  ldx #$00
  ldy #$10
  ; Skip the sprite zero.
  bpl StartAfterZero
Loop:
  sta sprite_v+$00,x
StartAfterZero:
  sta sprite_v+$40,x
  sta sprite_v+$80,x
  sta sprite_v+$c0,x
  inx
  inx
  inx
  inx
  dey
  bne Loop
  rts
.endproc


.proc ObjectAction
  ; push X
  txa
  pha
  lda object_kind,x
  tax
  ; Get values for the object from the tables below.
  mov speed, {table_object_speed,x}
  mov lifetime, {table_object_lifetime,x}
  pla
  tax
  rts
.endproc


.proc ObjectDraw
  txa
  pha
  tay
  mov pos_v, {object_pos_v,y}
  lda object_pos_h,y
  sec
  sbc camera_h
  sta pos_h
  lda object_kind,y
  tay
Draw:
  ; TODO: OAM cycling
  ; Left-side
  ldx #$80
  mov {sprite_tile,x}, {table_object_sprite0,y}
  mov {sprite_v,x},    pos_v
  mov {sprite_attr,x}, {table_object_attr,y}
  mov {sprite_h,x},    pos_h
  ; Advance
  lda pos_h
  clc
  adc #8
  sta pos_h
  ; Right-side
  ldx #$84
  lda table_object_sprite1,y
  beq Return
  sta sprite_tile,x
  mov {sprite_v,x},    pos_v
  mov {sprite_attr,x}, {table_object_attr,y}
  mov {sprite_h,x},    pos_h
Return:
  pla
  tax
  rts
.endproc


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



table_object_lifetime:
.byte 20

table_object_speed:
.byte 6

table_object_sprite0:
.byte $01

table_object_sprite1:
.byte $00

table_object_attr:
.byte $00
