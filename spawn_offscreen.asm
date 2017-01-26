.export SpawnOffscreenInit
.export SpawnOffscreenUpdate

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "object_list.h.asm"


.importzp spawn_left_index, spawn_right_index
.importzp camera_h, camera_screen, values
.importzp level_spawn_pointer

delta_h = values + $00
new_index = values + $01

.export offscreen_things
offscreen_things = $400


.segment "CODE"


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


.proc SpawnOffscreenUpdate
  jsr SpawnOffscreenToRight
  jmp SpawnOffscreenToLeft
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
  cmp #1
  bne Failure
  ;
  lda delta_h
  cmp #$10
  bge Failure
  ;
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
  cmp #$ff
  bne Failure
  ;
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
  ;
  jsr ObjectAllocate
  bcc Failure
  iny
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
  jsr ObjectConstructor
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
