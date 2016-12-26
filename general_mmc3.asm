.export GeneralMapperInit
.export GeneralMapperPrgBank8000

MMC3_BANK_SELECT = $8000
MMC3_BANK_DATA   = $8001

SELECT_PRG_8000   = $06
SELECT_PRG_A000   = $07

.segment "BOOT"

.proc GeneralMapperInit
  ldx #SELECT_PRG_A000
  stx MMC3_BANK_SELECT
  lda #($100 - 3)
  sta MMC3_BANK_DATA
  rts
.endproc


; A: Bank to swap in.
.proc GeneralMapperPrgBank8000
  ldx #SELECT_PRG_8000
  stx MMC3_BANK_SELECT
  sta MMC3_BANK_DATA
  rts
.endproc
