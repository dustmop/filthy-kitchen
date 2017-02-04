.export GeneralMapperInit
.export GeneralMapperPrg8000ToC000


.segment "BOOT"


.proc GeneralMapperInit
  rts
.endproc


bank_table:
.byte $00, $01, $02, $03


; A: Bank to swap in.
.proc GeneralMapperPrg8000ToC000
  tay
  lda bank_table,y
  sta bank_table,y
  rts
.endproc
