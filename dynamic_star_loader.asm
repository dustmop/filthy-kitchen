.export DynamicStarsLoad

.import stars_chr_data
.importzp values
count = values + $00

.include "include.branch-macros.asm"
.include "include.mov-macros.asm"
.include "render_action.h.asm"
.include "memory_layout.h.asm"
.include "general_mapper.h.asm"


.segment "BOOT"

; .reg.x @in Index into loader, 2..7 result in load
.proc DynamicStarsLoad
  txa
  sec
  sbc #2
  cmp #6
  bge Return
Load:
  .repeat 4
  asl a
  .endrepeat
  tax
  ; X = index * 16
  ; Bank switch
  lda #MEMORY_LAYOUT_BANK_SCREEN_CHR
  jsr GeneralMapperPrg8000ToC000
  ; Render action
  lda #16
  jsr AllocateRenderAction
  mov count, #16
  mov {render_action_addr_high,y}, #$1b
  mov {render_action_addr_low,y}, x
FillLoop:
  lda stars_chr_data,x
  sta render_action_data,y
  inx
  iny
  dec count
  bne FillLoop
Return:
  ; Undo bank switch.
  lda #MEMORY_LAYOUT_BANK_MAIN_CODE
  jsr GeneralMapperPrg8000ToC000
  rts
.endproc
