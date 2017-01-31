.export GeneralMapperInit
.export GeneralMapperPrg8000ToC000

A53_SELECT = $5000
A53_VALUE = $8000


.segment "BOOT"


.proc GeneralMapperInit
  ldy #$80
  sty A53_SELECT
  ; xxSS      = 01 ; Set prg outer bank size to 1 (64k)
  ; xxxx_PP   = 11 ; Set prg mode to 3 (UNROM #2)
  ; xxxx_xxMM = 10 ; Set mirroring to 2 (Horizontal arrangement)
  ; 0001_1110
  lda #$1e
  sta A53_VALUE
  rts
.endproc


; A: Bank to swap in.
; Clobbers Y
.proc GeneralMapperPrg8000ToC000
  ldy #1
  sty A53_SELECT
  sta A53_VALUE
  rts
.endproc
