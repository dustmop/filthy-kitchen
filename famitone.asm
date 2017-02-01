.export FamiToneInit
.export FamiToneSfxInit
.export FamiToneUpdate
.export FamiToneMusicPlay
.export FamiToneMusicStop
.export FamiToneMusicPause
.export FamiToneSfxPlay
.export FamiToneSamplePlay
.export music_data
.export sfx_data

.import music_samples

FT_BASE_ADR = $0100
FT_TEMP = $fd
FT_DPCM_OFF = music_samples
FT_SFX_STREAMS = 1
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

sfx_data:
.include ".b/sfx.s"
