.export FamiToneInit
.export FamiToneSfxInit
.export FamiToneUpdate
.export FamiToneMusicPlay
.export FamiToneMusicStop
.export FamiToneMusicPause
.export FamiToneSfxPlay
.export FamiToneSamplePlay
.export music_data

FT_BASE_ADR = $0100
FT_TEMP = $fd
FT_DPCM_OFF = $c000
FT_SFX_STREAMS = 4
FT_THREAD = 1

FT_PAL_SUPPORT = 0
FT_SFX_ENABLE = 1
FT_NTSC_SUPPORT = 1
FT_PITCH_FIX = 0
FT_DPCM_ENABLE = 1

.segment "CODE"

.include "third_party/famitone2.s"

music_data:
.include ".b/music.s"