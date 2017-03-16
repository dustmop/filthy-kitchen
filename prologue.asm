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


.segment "GFX0"

title_graphics:
.include ".b/title.compressed.asm"

game_over_graphics:
.include ".b/game_over.compressed.asm"


.segment "VECTORS"

.import NMI, RESET

.word NMI
.word RESET
.word 0


.segment "GFX0"

.export gameplay0_bg_chr_data
gameplay0_bg_chr_data:
.include ".b/resource0.compress.asm"

.export gameplay1_bg_chr_data
gameplay1_bg_chr_data:
.include ".b/resource1.compress.asm"

.export chars_spr_chr_data
chars_spr_chr_data:
.include ".b/resource2.compress.asm"

.export chars_boss_spr_chr_data
chars_boss_spr_chr_data:
.include ".b/resource3.compress.asm"

.export boss_bg_chr_data
boss_bg_chr_data:
.include ".b/resource4.compress.asm"


.segment "GFX2"

.export title_bg_chr_data
title_bg_chr_data:
.include ".b/resource5.compress.asm"
