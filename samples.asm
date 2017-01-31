.export music_samples

.segment "BOOT"

.align 64
music_samples:
.incbin ".b/music.dmc"
