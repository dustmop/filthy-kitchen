.export SpawnOffscreenInit
.export SpawnOffscreenUpdate
.export SpawnOffscreenFillEntireScreen
.export GetLeftmostObject

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "object_list.h.asm"


.importzp spawn_left_index, spawn_right_index
.importzp camera_h, camera_screen, values
.importzp level_spawn_pointer
.import SetLevelBank, RevertLevelBank

delta_h = values + $00
new_index = values + $01
leftmost_w = values + $02
leftmost_h = values + $03
leftmost_idx = values + $04

.export offscreen_things
offscreen_things = $400


.segment "BOOT"


.proc SpawnOffscreenInit
  mov spawn_left_index, #$ff
  mov spawn_right_index, #0
  ldx #0
Loop:
  sta offscreen_things,x
  inx
  cpx #$40
  bne Loop
  rts
.endproc


.proc SpawnOffscreenFillEntireScreen
  jsr SetLevelBank
  mov camera_h, #$10
  mov camera_screen, #$ff
Loop:
  jsr SpawnOffscreenToRight
  lda camera_h
  clc
  adc #$10
  sta camera_h
  bne Loop
  mov camera_h, #$00
  mov camera_screen, _
  jsr RevertLevelBank
  rts
.endproc


.proc SpawnOffscreenUpdate
  jsr SetLevelBank
  jsr SpawnOffscreenToRight
  jsr SpawnOffscreenToLeft
  jsr RevertLevelBank
  rts
.endproc


.proc SpawnOffscreenToRight
  ; Get spawn index * 4.
  lda spawn_right_index
  asl a
  asl a
  tay
  ;
  lda (level_spawn_pointer),y ; v
  cmp #$ff
  beq Failure
  ;
  iny
  lda (level_spawn_pointer),y ; h
  sec
  sbc camera_h
  sta delta_h
  ;
  iny
  lda (level_spawn_pointer),y ; w
  sbc camera_screen
  beq Success
  cmp #1
  bne Failure
  ;
  lda delta_h
  cmp #$10
  bge Failure
  ;
Success:
  mov new_index, spawn_right_index
  ;
  ldx spawn_right_index
  inc spawn_right_index
  lda offscreen_things,x
  bne Failure
  ;
  jmp AllocateAndConstruct
Failure:
  clc
  rts
.endproc


.proc SpawnOffscreenToLeft
  lda spawn_left_index
  cmp #$ff
  beq Failure
  ;
  asl a
  asl a
  tay
  ;
  ; skip v
  iny
  lda (level_spawn_pointer),y ; h
  sec
  sbc camera_h
  sta delta_h
  ;
  iny
  lda (level_spawn_pointer),y ; w
  sbc camera_screen
  beq Success
  cmp #$ff
  bne Failure
  ;
Success:
  lda delta_h
  cmp #$f0
  blt Failure
  ;
  mov new_index, spawn_left_index
  ;
  ldx spawn_left_index
  dec spawn_left_index
  lda offscreen_things,x
  bne Failure
  ;
  jmp AllocateAndConstruct
Failure:
  clc
  rts
.endproc


.proc AllocateAndConstruct
  ; Point to id
  iny
  ; Allocate an object.
  jsr ObjectAllocate
  bcs Allocated
  ; Allocation failed, check if this is the broom.
  lda (level_spawn_pointer),y ; id
  cmp #OBJECT_KIND_BROOM
  bne Failure
  ; If it is, usurp the left-most object.
  jsr GetLeftmostObject
Allocated:
  lda (level_spawn_pointer),y ; id
  and #$0f
  sta object_kind,x
  ;
  .repeat 3
  dey
  .endrepeat
  lda (level_spawn_pointer),y ; v
  sta object_v,x
  iny
  lda (level_spawn_pointer),y ; h
  sta object_h,x
  iny
  lda (level_spawn_pointer),y ; w
  sta object_screen,x
  iny
  lda (level_spawn_pointer),y ; id
  .repeat 4
  lsr a
  .endrepeat
  tay
  jsr RevertLevelBank
  jsr ObjectConstructor
  jsr SetLevelBank
Success:
  ldy new_index
  tya
  sta object_index,x
  mov {offscreen_things,y}, #$ff
  sec
  rts
Failure:
  clc
  rts
.endproc


.proc GetLeftmostObject
  ldx #0
  lda object_kind,x
  cmp #$ff
  beq Found
  mov {leftmost_w}, {object_screen,x}
  mov {leftmost_h}, {object_h,x}
  stx leftmost_idx
  inx
Loop:
  lda object_kind,x
  cmp #$ff
  beq Found
  lda object_screen,x
  cmp leftmost_w
  blt NewLeftmost
  bne Increment
  lda object_h,x
  cmp leftmost_h
  blt NewLeftmost
  bge Increment
NewLeftmost:
  mov {leftmost_w}, {object_screen,x}
  mov {leftmost_h}, {object_h,x}
  stx leftmost_idx
Increment:
  inx
  cpx #$10
  bne Loop
  ldx leftmost_idx
Found:
  rts
.endproc
