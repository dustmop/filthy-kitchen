.segment "INESHDR"

MAPPER_NUMBER = 0


.byte "NES", $1a
.byte $02 ; prg * $4000
.byte $00 ; chr-ram
.byte ((MAPPER_NUMBER & $0f) << 4) | $01
.byte (MAPPER_NUMBER & $f0) | $00
.byte $00 ; 8) mapper variant
.byte $00 ; 9) upper bits of ROM size
.byte $00 ; 10) prg ram
.byte $00 ; 11) chr ram (0)
.byte $00 ; 12) tv system - ntsc
.byte $00 ; 13) vs hardware
.byte $00 ; reserved
.byte $00 ; reserved


.segment "CODE"

.export palette

palette:
;.incbin ".b/resource.palette.dat"
.byte $0f,$21,$18,$10,$0f,$30,$10,$00,$0f,$27,$10,$0f,$0f,$0f,$0f,$0f
.byte $0f,$26,$0f,$16,$0f,$37,$30,$0c,$0f,$3b,$1c,$0c,$0f,$39,$0a,$00
;.byte $0f,$34,$0f,$16,$0f,$37,$30,$0c,$0f,$3b,$1c,$0c,$0f,$39,$0a,$00


.segment "VECTORS"

.import NMI, RESET

.word NMI
.word RESET
.word 0


.segment "CHRDATA"

.export chr_data

chr_data:
.incbin ".b/resource.chr.dat"
