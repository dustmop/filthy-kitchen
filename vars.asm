.segment "ZEROPAGE" : zeropage

main_yield: .byte 0
ppu_ctrl_current: .byte 0
ppu_mask_current: .byte 0
bg_x_scroll: .byte 0
bg_y_scroll: .byte 0
buttons: .byte 0
buttons_last: .byte 0
buttons_press: .byte 0
pointer: .word 0
player_v: .byte 0
player_h: .byte 0
player_h_low: .byte 0
player_jump: .byte 0
player_jump_low: .byte 0
player_screen: .byte 0
player_render_v: .byte 0
player_render_h: .byte 0
camera_h: .byte 0
camera_screen: .byte 0
values: .word 0,0,0,0,0,0,0,0
NMI_SCROLL_target: .byte 0
NMI_SCROLL_strip_id: .byte 0
NMI_SCROLL_action: .byte 0
NMI_pointer: .word 0
NMI_values: .word 0,0,0,0
object_list_head: .byte 0
object_list_tail: .byte 0
sprite_space_index: .byte 0
sprite_space_avail: .byte 0
sprite_space_force: .byte 0
level_max_h: .byte 0
level_max_screen: .byte 0
level_max_camera_h: .byte 0
level_max_camera_screen: .byte 0


.exportzp main_yield, ppu_ctrl_current, ppu_mask_current
.exportzp bg_x_scroll, bg_y_scroll, buttons, buttons_last, buttons_press
.exportzp player_v, player_h, player_h_low, player_screen
.exportzp player_jump, player_jump_low, player_render_v, player_render_h
.exportzp camera_h, camera_screen
.exportzp values, pointer
.exportzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.exportzp NMI_values, NMI_pointer
.exportzp object_list_head, object_list_tail
.exportzp sprite_space_index, sprite_space_avail, sprite_space_force
.exportzp level_max_h, level_max_screen
.exportzp level_max_camera_h, level_max_camera_screen

collision_map = $500

.export collision_map
