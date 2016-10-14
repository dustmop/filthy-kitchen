.import ObjectListInit
.import ObjectListUpdate
.import ObjectAllocate
.import ObjectFree
.import ObjectConstruct

OBJECT_KIND_SWATTER = $00

.import object_data
object_kind  = object_data + $00
object_next  = object_data + $10
object_pos_v = object_data + $10
object_pos_h = object_data + $20
object_dir   = object_data + $30
object_frame = object_data + $40
object_step  = object_data + $50
object_life  = object_data + $60
