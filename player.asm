.export PlayerInit
.export PlayerUpdate
.export PlayerDraw

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.controller.asm"
.include "include.sprites.asm"

.importzp player_v, player_h, buttons
.importzp values

PLAYER_TILE = $00

offset_v    = values + $00
offset_h    = values + $01
offset_tile = values + $02


.segment "CODE"


.proc PlayerInit
  mov player_v, #$a0
  mov player_h, #$40
  rts
.endproc


.proc PlayerUpdate
  lda buttons
  and #BUTTON_LEFT
  bne MoveLeft
  lda buttons
  and #BUTTON_RIGHT
  bne MoveRight
  beq Done
MoveLeft:
  dec player_h
  jmp Done
MoveRight:
  inc player_h
Done:
  rts
.endproc


.proc PlayerDraw
  ldx #$00

  ; Row 0
  mov offset_v, player_v
  dec offset_v
  mov offset_h, player_h
  mov offset_tile, #PLAYER_TILE
  jsr DrawSingleTile
  jsr DrawRightSideTile

  ; Row 1
  inc offset_tile
  lda offset_v
  clc
  adc #8
  sta offset_v
  mov offset_h, player_h
  .repeat 4
  inx
  .endrepeat
  jsr DrawSingleTile
  jsr DrawRightSideTile

  ; Row 2
  inc offset_tile
  lda offset_v
  clc
  adc #8
  sta offset_v
  mov offset_h, player_h
  .repeat 4
  inx
  .endrepeat
  jsr DrawSingleTile
  jsr DrawRightSideTile

  ; Row 3
  inc offset_tile
  lda offset_v
  clc
  adc #8
  sta offset_v
  mov offset_h, player_h
  .repeat 4
  inx
  .endrepeat
  jsr DrawSingleTile
  fallt DrawRightSideTile
.endproc


.proc DrawRightSideTile
  inc offset_tile
  lda offset_h
  clc
  adc #8
  sta offset_h
  .repeat 4
  inx
  .endrepeat
  fallt DrawSingleTile
.endproc


.proc DrawSingleTile
  mov {sprite_v,x}, offset_v
  mov {sprite_tile,x}, offset_tile
  mov {sprite_attr,x}, #$00
  mov {sprite_h,x}, offset_h
  rts
.endproc
