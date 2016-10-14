.export ObjectListInit
.export ObjectListUpdate
.export ObjectAllocate
.export ObjectFree
.export ObjectConstruct

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sprites.asm"
.include "draw_picture.h.asm"

.importzp object_list_head, object_list_tail, camera_h
.importzp values

;DrawPicture    values + $00
speed         = values + $01
frame         = values + $02
lifetime      = values + $03
picture_id    = values + $04
animate_limit = values + $05
num_frames    = values + $06
flip_bits     = values + $07


.export object_data
object_data  = $440
object_kind  = object_data + $00
object_next  = object_data + $10
object_pos_v = object_data + $10
object_pos_h = object_data + $20
object_dir   = object_data + $30
object_frame = object_data + $40
object_step  = object_data + $50
object_life  = object_data + $60


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
  ldx #0
Loop:
  lda object_kind,x
  bmi Increment
Body:
  jsr ObjectRetrieveInfo
  mov draw_v, {object_pos_v,x}
  ; TODO: Direction
  ; Move forward
  lda object_pos_h,x
  clc
  adc speed
  sta object_pos_h,x
  sec
  sbc camera_h
  sta draw_h
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
  ; Step forward lifetime
  inc object_life,x
  lda object_life,x
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


