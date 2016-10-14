.export ObjectListInit
.export ObjectListUpdate
.export ObjectAllocate
.export ObjectFree
.export ObjectConstruct

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.scroll-action.asm"
.include "include.sprites.asm"
.include "sprite_space.h.asm"

.importzp object_list_head, object_list_tail, camera_h
.importzp values

pos_v         = values + $00
pos_h         = values + $01
speed         = values + $02
frame         = values + $03
lifetime      = values + $04
picture_id    = values + $05
animate_limit = values + $06
num_frames    = values + $07
flip_bits     = values + $08


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
  ; TODO: Direction
  ; Move forward
  lda object_pos_h,x
  clc
  adc speed
  sta object_pos_h,x
  sec
  sbc camera_h
  sta pos_h
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
  mov frame, {object_frame,x}
  ; Draw the sprites.
  jsr ObjectDraw
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
  mov pos_v, {object_pos_v,x}
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


.proc ObjectDraw
  txa
  pha
  tay
  ;lda object_kind,y
  ;tay
  ldy frame
  lda swatter_animation_sequence,y
  tay
FrameLoop:
  lda swatter_frames,y
  cmp #$ff
  beq FrameDone
  and #$3f
  sta picture_id
  lda swatter_frames,y
  and #$c0
  sta flip_bits
  jsr DrawSinglePicture
  lda pos_h
  clc
  adc #8
  sta pos_h
  iny
  bne FrameLoop
FrameDone:
  pla
  tax
  rts
.endproc


.proc DrawSinglePicture
  tya
  pha
  ldy picture_id
  jsr SpriteSpaceAllocate
  ; V
  lda picture_data,y
  clc
  adc pos_v
  sta sprite_v,x
  iny
  ; H
  lda picture_data,y
  clc
  adc pos_h
  sta sprite_h,x
  iny
  ; tile
  lda picture_data,y
  sta sprite_tile,x
  ; attr
  lda flip_bits
  sta sprite_attr,x
  pla
  tay
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

swatter_animation_sequence:
.byte $06,$03,$00,$13,$11,$0e,$0b,$08

swatter_frames:
swatter_dir_0: ; horizontal, offset=$00
.byte $00,$03,$ff

swatter_dir_1: ; diagonal up-right, offset=$03
.byte $06,$09,$ff

swatter_dir_2: ; vertical, offset=$06
.byte $0c,$ff

swatter_dir_3: ; diagonal up-left, offset=$08
.byte $49,$46,$ff

swatter_dir_4: ; horizontal, offset=$0b
.byte $43,$40,$ff

swatter_dir_5: ; diagonal down-left, offset=$0e
.byte $d2,$cf,$ff

swatter_dir_6: ; vertical, offset=$11
.byte $8c,$ff

swatter_dir_7: ; diagonal down-right, offset=$13
.byte $8f,$92,$ff

picture_data:
; swatter horizontal, left-half
; { v=6, h=0, tile=7 },  picture_id = $00
.byte $06, $00, $07
; swatter horizontal, right-half
; { v=-5, h=8, tile=9 }, picture_id = $03
.byte $fb, $00, $09
; swatter up-diag, left-half
; { v=9, h=-1, tile=3 }, picture_id = $06
.byte $09, $ff, $03
; swatter up-diag, right-half
; { v=-7, h=7, tile=5 }, picture_id = $09
.byte $f9, $ff, $05
; swatter vertical
; { v=0, h=4, tile=1 },  picture_id = $0c
.byte $00, $04, $01
; swatter down-diag, left-half
; { v=-9, h=-1, tile=3 }, picture_id = $0f
.byte $f7, $ff, $03
; swatter down-diag, right-half
; { v=7, h=7, tile=5 }, picture_id = $12
.byte $07, $ff, $05
