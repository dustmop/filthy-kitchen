.import MemoryLayoutInit
.import MemoryLayoutFillChrRam
.import MemoryLayoutLoadNametable

MEMORY_LAYOUT_BANK_GAMEPLAY_CHR = 0
MEMORY_LAYOUT_BANK_SCREEN_CHR = 1
MEMORY_LAYOUT_BANK_LEVEL_DAT = 1
MEMORY_LAYOUT_BANK_MAIN_CODE = 2

.importzp GAMEPLAY0_MEMORY_LAYOUT
.importzp GAMEPLAY1_MEMORY_LAYOUT
.importzp BOSS_MEMORY_LAYOUT
.importzp TITLE_MEMORY_LAYOUT
