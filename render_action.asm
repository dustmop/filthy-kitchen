.export AllocateRenderAction
.export RenderActionApplyAll

.importzp render_last
.importzp NMI_values

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "include.sys.asm"
.include "gfx.h.asm"

apply_count = NMI_values + $00

render_action_buffer = $700
RENDER_ACTION_HEADER_SIZE = 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RenderAction is struct in memory, page $7
; 0: size of action
; 1: ppu addr, high byte
; 2: ppu addr, low byte
; 3: buffer data, of size given at (0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CODE"

;AllocateRenderAction
; Allocate a RenderAction object, returning its index to the caller.
; .reg:a @in  Size of object to allocate.
; .reg:y @out Index to allocated object.
.proc AllocateRenderAction
  pha
  ldy render_last
  sta render_action_buffer,y
  clc
  adc render_last
  adc #RENDER_ACTION_HEADER_SIZE
  sta render_last
  pla
  rts
.endproc

;RenderActionsApply
; Apply all RenderActions in the $0700 page.
; Clobbers A,X,Y
.proc RenderActionApplyAll
  jsr PrepareRenderHorizontal
  ldx #0
  stx apply_count
UpdateLoop:
  cpx render_last
  bge Done
  ; Don't need to clc, because bge implies carry is clear.
  lda render_action_buffer,x
  adc apply_count
  adc #RENDER_ACTION_HEADER_SIZE
  sta apply_count
  ; Set ppu address.
  lda render_action_buffer+1,x
  sta PPU_ADDR
  lda render_action_buffer+2,x
  sta PPU_ADDR
  ; Begin update loop.
  inx ; Size of RenderActions header.
  inx
  inx
Loop:
  mov PPU_DATA, {render_action_buffer,x}
  inx
  cpx apply_count
  bne Loop
  beq UpdateLoop
Done:
  ; Clear bg update memory.
  mov render_last, #0
  rts
.endproc
