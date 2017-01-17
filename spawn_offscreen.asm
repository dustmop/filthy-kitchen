.export SpawnOffscreenInit
.export SpawnOffscreenUpdate

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "object_list.h.asm"


.importzp spawn_index
.importzp camera_h, camera_screen, values
.import level_spawn

delta_h = values + $00


spawn_data_v  = level_spawn + 0
spawn_data_h  = level_spawn + 1
spawn_data_w  = level_spawn + 2
spawn_data_id = level_spawn + 3


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
  lda spawn_data_v,y
  cmp #$ff
  beq Failure
  ;
  lda spawn_data_h,y
  sec
  sbc camera_h
  sta delta_h
  lda spawn_data_w,y
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
  lda spawn_data_id,y
  and #$0f
  sta object_kind,x
  mov {object_screen,x}, {spawn_data_w,y}
  mov {object_v,x}, {spawn_data_v,y}
  mov {object_h,x}, {spawn_data_h,y}
  lda spawn_data_id,y
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
