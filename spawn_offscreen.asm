.export SpawnOffscreenInit
.export SpawnOffscreenUpdate

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "object_list.h.asm"


.importzp spawn_index
.importzp camera_h, camera_screen, values
.importzp level_spawn_pointer

delta_h = values + $00


.segment "CODE"


.proc SpawnOffscreenInit
  mov spawn_index, #0
  rts
.endproc


.proc SpawnOffscreenUpdate
  lda spawn_index
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
  inc spawn_index
  sec
  rts
Failure:
  clc
  rts
.endproc
