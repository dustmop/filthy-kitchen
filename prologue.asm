.segment "INESHDR"

MAPPER_NUMBER = 4


.byte "NES", $1a
.byte $04 ; prg * $4000
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
.incbin ".b/bg_pal.dat"
.incbin ".b/sprite_pal.dat"


.segment "VECTORS"

.import NMI, RESET

.word NMI
.word RESET
.word 0


.segment "CHRDATA0"

.export chr_data

chr_data:
.incbin ".b/resource.chr.dat"

.segment "CHRDATA1"

.byte $01

.segment "CHRDATA2"

.byte $02

.segment "CHRDATA3"

.byte $03

.segment "CHRDATA4"

.byte $04
