.export ObjectListInit
.export ObjectListUpdate
.export ObjectListCountAvail
.export ObjectListGetLast
.export ObjectAllocate
.export ObjectFree
.export ObjectConstructor
.export ObjectOffscreenDespawn
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
.include "dirt.h.asm"
.include "utensils.h.asm"
.include "broom.h.asm"
.include "gunk_drop.h.asm"
.include "trash_gunk.h.asm"
.include "star.h.asm"
.include "wing.h.asm"
.include "toaster.h.asm"
.include "sploosh.h.asm"
.include "blender.h.asm"
.include "shared_object_values.asm"
.include "collision_data.h.asm"


.importzp object_list_head, object_list_tail, camera_h
.importzp player_v, player_h, player_screen, player_collision_idx, is_paused
.importzp objects_only_draw, draw_frame
.importzp values
; TODO: Circular dependency, bad.
.import offscreen_things
.importzp spawn_left_index, spawn_right_index

.export object_data, object_index
object_data   = $440
object_kind   = object_data + $00
object_next   = object_data + $10
object_index  = object_data + $10
object_v      = object_data + $20
object_h      = object_data + $30
object_screen = object_data + $40
object_frame  = object_data + $50
object_step   = object_data + $60
object_life   = object_data + $70
.export object_data_extend
object_data_extend = object_data + $80


OBJECT_KIND_NONE = $ff
OBJECT_KIND_SWATTER    = $00
OBJECT_KIND_FLY        = $01
OBJECT_KIND_EXPLODE    = $02
OBJECT_KIND_POINTS     = $03
OBJECT_KIND_FOOD       = $04
OBJECT_KIND_DIRTY_SINK = $05
OBJECT_KIND_UTENSILS   = $06
OBJECT_KIND_BROOM      = $07
OBJECT_KIND_GUNK_DROP  = $08
OBJECT_KIND_STAR       = $09
OBJECT_KIND_WING       = $0a
OBJECT_KIND_TOASTER    = $0b
OBJECT_KIND_SPLOOSH    = $0c
OBJECT_KIND_TRASH_GUNK = $0d
OBJECT_KIND_BLENDER    = $0e

OBJECT_IS_NEW = $40
OBJECT_CLEAR_NEW = $3f

MAX_NUM_OBJECTS = 16


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


.proc ObjectListGetLast
  ldx #(MAX_NUM_OBJECTS - 1)
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
  jsr ObjectExecute
  bit is_paused
  bmi Increment
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


.proc ObjectExecute
  lda object_kind,x
  tay
  ; Retrieve info for the object.
  mov animate_limit, {table_object_animate_limit,y}
  mov num_frames,    {table_object_num_frames,y}
  ; No animation if paused
  bit is_paused
  bmi Next
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
  lda objects_only_draw
  bne OnlyDraw
Execute:
  txa
  pha
  tya
  asl a
  tay
  jsr ObjectExecuteFromTable
  pla
  tax
Return:
  rts
OnlyDraw:
  txa
  pha
  tya
  asl a
  tay
  jsr ObjectDrawFromTable
  pla
  tax
  rts
.endproc


.proc ObjectExecuteFromTable
  lda execute_table+1,y
  pha
  lda execute_table+0,y
  pha
  rts
.endproc


.proc ObjectDrawFromTable
  lda draw_table+1,y
  pha
  lda draw_table+0,y
  pha
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


.proc ObjectOffscreenDespawn
  ; TODO: Circular dependency, bad.
  lda object_h,x
  sec
  sbc player_h
  lda object_screen,x
  sbc player_screen
  eor #$80
  cmp #$81
  bge DespawnRight
  cmp #$7f
  blt DespawnLeft
  bge Failure
DespawnLeft:
  lda object_index,x
  sta spawn_left_index
  jmp DespawnObject
DespawnRight:
  lda object_index,x
  sta spawn_right_index
DespawnObject:
  tay
  lda #$00
  sta offscreen_things,y
  jsr ObjectFree
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc ObjectCollisionWithPlayer
  mov delta_dir, #0

  ldy player_collision_idx
  lda collision_data_player,y ; h_offset
  sta delta_h
  iny
  lda collision_data_player,y ; v_offset
  sta delta_v

  ldy object_kind,x
  bmi Failure
  ; Calculate deltas from player.
DeltaCalcV:
  ; delta = abs(object - offset - player)
  lda object_v,x
  sec
  sbc delta_v
  sec
  sbc player_v
  bpl AbsoluteV
  eor #$ff
  clc
  adc #1
  bvs RadialDeltaV
AbsoluteV:
  sec
  sbc kind_bigger_v,y
  bpl RadialDeltaV
  lda #0
RadialDeltaV:
  sta delta_v
DeltaCalcH:
  ; delta = abs(object - offset - player)
  lda object_h,x
  sec
  sbc delta_h
  sec
  sbc kind_offset_h,y
  sec
  sbc player_h
  sta delta_h
  lda object_screen,x
  sbc player_screen
  ; Check that screen is 0 or -1.
  beq Okay
  cmp #$ff
  bne Failure
  ; To the left, change direction.
  dec delta_dir
  lda delta_h
  bpl Overflow
  eor #$ff
  clc
  adc #1
  sta delta_h
  bvs RadialDeltaH
  bvc Okay
Overflow:
  mov delta_h, #$ff
Okay:
  lda delta_h
  bmi RadialDeltaH
  sec
  sbc kind_bigger_h,y
  bpl RadialDeltaH
  lda #0
RadialDeltaH:
  sta delta_h

  ; Maybe collide with player.
  ldy player_collision_idx
  iny
  iny
  lda delta_h
  cmp collision_data_player,y ; h_hitbox
  bge Failure
  iny
  lda delta_v
  cmp collision_data_player,y ; v_hitbox
  bge Failure
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.segment "BOOT"

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
  bne Success
AssignEmptyList:
  ; Allocate the last element from the list.
  mov object_list_head, #$ff
  mov object_list_tail, _
Success:
  sec
  rts
Failure:
  clc
  rts
.endproc


.segment "CODE"

.proc ObjectConstructor
  lda #0
  sta object_frame,x
  sta object_step,x
  lda #$ff
  sta object_life,x
  lda object_kind,x
  cmp #OBJECT_KIND_FLY
  beq Fly
  cmp #OBJECT_KIND_FOOD
  beq Food
  cmp #OBJECT_KIND_UTENSILS
  beq Utensils
  cmp #OBJECT_KIND_DIRTY_SINK
  beq Dirt
  cmp #OBJECT_KIND_STAR
  beq Star
  cmp #OBJECT_KIND_WING
  beq Wing
  cmp #OBJECT_KIND_TOASTER
  beq Toaster
  cmp #OBJECT_KIND_BLENDER
  beq Blender
  rts
Fly:
  jsr FlyConstructor
  rts
Food:
  jsr FoodConstructor
  rts
Utensils:
  jsr UtensilsConstructor
  rts
Dirt:
  jsr DirtConstructor
  rts
Star:
  jsr StarConstructor
  rts
Wing:
  jsr WingConstructor
  rts
Toaster:
  jsr ToasterConstructor
  rts
Blender:
  jsr BlenderConstructor
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



;SWATTER, FLY, EXPLODE, POINTS, FOOD, DIRTY, UTENTILS, BROOM, GUNK_DROP, STAR
;   WING, TOASTER, SPLOOSH, TRASH_GUNK, BLENDER

table_object_num_frames:
.byte   8,  3,       3,      1,    8,     1,        1,     8,         1,    4
.byte $80,      6,       3,          1,       6

table_object_animate_limit:
.byte   2,  3,       6,      1,    4,     1,        1,     4,         1,    4
.byte $80,      4,       6,          1,       4

kind_offset_h:
.byte   0,  5,     $80,    $80,    3,     0,        0,     0,         4,  $80
.byte $80,      0,       4,          4,       0

kind_bigger_h:
.byte   0,  0,     $80,    $80,    8,     4,        0,     8,         3,  $80
.byte $80,      2,       3,          3,       2

kind_bigger_v:
.byte   0,  0,     $80,    $80,    2,     2,        0,    30,         3,  $80
.byte $80,     12,       3,          3,       2

execute_table:
.word SwatterExecute-1
.word FlyExecute-1
.word ExplodeExecute-1
.word PointsExecute-1
.word FoodExecute-1
.word DirtExecute-1
.word UtensilsExecute-1
.word BroomExecute-1
.word GunkDropExecute-1
.word StarExecute-1
.word WingExecute-1
.word ToasterExecute-1
.word SplooshExecute-1
.word TrashGunkExecute-1
.word BlenderExecute-1

draw_table:
.word SwatterDraw-1
.word FlyDraw-1
.word ExplodeDraw-1
.word PointsDraw-1
.word FoodDraw-1
.word DirtDraw-1
.word UtensilsDraw-1
.word BroomDraw-1
.word GunkDropDraw-1
.word StarDraw-1
.word WingDraw-1
.word ToasterDraw-1
.word SplooshDraw-1
.word TrashGunkDraw-1
.word BlenderDraw-1
