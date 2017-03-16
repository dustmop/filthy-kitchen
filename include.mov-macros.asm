.macro mov dst,src
.if .xmatch({src}, x)
  txa
.elseif .xmatch({src}, y)
  tya
.elseif (.not .xmatch({src}, _))
  lda src
.endif
  sta dst
.endmacro

.macro MovWord dst,src
  lda #<src
  sta dst+0
  lda #>src
  sta dst+1
.endmacro
