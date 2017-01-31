.export GeneralMapperInit
.export GeneralMapperPrg8000ToC000

MMC3_BANK_SELECT = $8000
MMC3_BANK_DATA   = $8001

SELECT_PRG_8000   = $06
SELECT_PRG_A000   = $07

.segment "BOOT"

.proc GeneralMapperInit
  rts
.endproc


; A: Bank to swap in.
; Clobbers Y
.proc GeneralMapperPrg8000ToC000
  ldy #SELECT_PRG_8000
  sty MMC3_BANK_SELECT
  asl a
  sta MMC3_BANK_DATA
  ldy #SELECT_PRG_A000
  sty MMC3_BANK_SELECT
  clc
  adc #1
  sta MMC3_BANK_DATA
  rts
.endproc
