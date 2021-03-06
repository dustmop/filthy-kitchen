.import ObjectListInit
.import ObjectListUpdate
.import ObjectListCountAvail
.import ObjectListGetLast
.import ObjectAllocate
.import ObjectFree
.import ObjectConstructor
.import ObjectOffscreenDespawn
.import ObjectCollisionWithPlayer
.import ObjectMovementApplyDelta

OBJECT_KIND_SWATTER    = $00
OBJECT_KIND_FLY        = $01
OBJECT_KIND_EXPLODE    = $02
OBJECT_KIND_POINTS     = $03
OBJECT_KIND_FOOD       = $04
OBJECT_KIND_DIRTY_SINK = $05
OBJECT_KIND_UTENSILS   = $06
OBJECT_KIND_BROOM      = $07
OBJECT_KIND_GUNK_DROP  = $08
OBJECT_KIND_STAR       = $09
OBJECT_KIND_WING       = $0a
OBJECT_KIND_TOASTER    = $0b
OBJECT_KIND_SPLOOSH    = $0c
OBJECT_KIND_TRASH_GUNK = $0d

OBJECT_IS_NEW = $40

.import object_index
.import object_data
object_kind   = object_data + $00
object_next   = object_data + $10
object_v      = object_data + $20
object_h      = object_data + $30
object_screen = object_data + $40
object_frame  = object_data + $50
object_step   = object_data + $60
object_life   = object_data + $70
