.segment "INESHDR"

.import MAPPER_NUMBER

.byte "NES", $1a
.byte $04 ; prg * $4000
.byte $00 ; chr-ram
.byte ((<MAPPER_NUMBER & $0f) << 4) | $01
.byte (<MAPPER_NUMBER & $f0) | $00
.byte $00 ; 8) mapper variant
.byte $00 ; 9) upper bits of ROM size
.byte $00 ; 10) prg ram
.byte $00 ; 11) chr ram (0)
.byte $00 ; 12) tv system - ntsc
.byte $00 ; 13) vs hardware
.byte $00 ; reserved
.byte $00 ; reserved


.segment "CODE"

.export gameplay_palette
.export title_palette, title_graphics
.export game_over_palette, game_over_graphics
.export text_palette

gameplay_palette:
.incbin ".b/bg_pal.dat"
.incbin ".b/sprite_pal.dat"

title_palette:
game_over_palette:
.incbin ".b/title.palette.dat"
.byte $11,$30,$10,$00
.byte $11,$0f,$0f,$0f
.byte $11,$0f,$0f,$0f
.byte $11,$0f,$0f,$0f

text_palette:
.incbin ".b/text_pal.dat"
.incbin ".b/sprite_pal.dat"

title_graphics:
.include ".b/title.compressed.asm"

game_over_graphics:
.include ".b/game_over.compressed.asm"


.segment "VECTORS"

.import NMI, RESET

.word NMI
.word RESET
.word 0


.segment "CHRDATA0"
.export chr_data
chr_data:
.incbin ".b/resource0.chr.dat"

.segment "CHRDATA1"
.export boss_chr_data
boss_chr_data:
.incbin ".b/resource1.chr.dat"

.segment "CHRDATA2"
.export title_chr_data
title_chr_data:
.incbin ".b/resource2.chr.dat"

.segment "CHRDATA3"

.byte $03
