.macro bge label
  bcs label
.endmacro

.macro blt label
  bcc label
.endmacro

.macro jeq Label
  .local Otherwise
  bne Otherwise
  jmp Label
Otherwise:
.endmacro

.macro jne Label
  .local Otherwise
  beq Otherwise
  jmp Label
Otherwise:
.endmacro

.macro fallt label
  .assert * = label, error, "Fall-through failed"
.endmacro

.macro skip2
  .byte $2c
.endmacro
