.import ObjectListInit
.import ObjectListUpdate
.import ObjectListCountAvail
.import ObjectAllocate
.import ObjectFree
.import ObjectConstruct
.import ObjectCollisionWithPlayer
.import ObjectMovementApplyDelta

OBJECT_KIND_SWATTER = $00
OBJECT_KIND_FLY     = $01
OBJECT_KIND_EXPLODE = $02
OBJECT_KIND_POINTS  = $03
OBJECT_KIND_FOOD    = $04

OBJECT_IS_NEW = $40

.import object_data
object_kind   = object_data + $00
object_next   = object_data + $10
object_v      = object_data + $10
object_h      = object_data + $20
object_screen = object_data + $30
object_frame  = object_data + $40
object_step   = object_data + $50
object_life   = object_data + $60
