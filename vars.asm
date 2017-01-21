.segment "ZEROPAGE" : zeropage

; sys
main_yield: .byte 0
ppu_ctrl_current: .byte 0
ppu_mask_current: .byte 0
debug_mode: .byte 0
render_last: .byte 0
pointer: .word 0
values: .word 0,0,0,0,0,0,0,0

; nmi
NMI_SCROLL_target: .byte 0
NMI_SCROLL_strip_id: .byte 0
NMI_SCROLL_action: .byte 0
NMI_pointer: .word 0
NMI_values: .word 0,0,0,0

; level
level_state_begin:
bg_x_scroll: .byte 0
bg_y_scroll: .byte 0
bg_nt_select: .byte 0
buttons: .byte 0
buttons_last: .byte 0
buttons_press: .byte 0
camera_h: .byte 0
camera_screen: .byte 0
spawn_index: .byte 0
level_max_screen: .byte 0
level_has_entrance_door: .byte 0
level_has_infinite_flies: .byte 0
level_player_start_v: .byte 0
level_complete: .byte 0
level_data_pointer: .word 0
level_chunk_pointer: .word 0
level_table_of_contents_pointer: .word 0
level_spawn_pointer: .word 0
level_state_end:

; player state
player_state_begin:
player_v: .byte 0
player_h: .byte 0
player_h_low: .byte 0
player_dir: .byte 0
player_gravity: .byte 0
player_gravity_low: .byte 0
player_screen: .byte 0
player_render_v: .byte 0
player_render_h: .byte 0
player_owns_swatter: .byte 0
player_state: .byte 0
player_collision_idx: .byte 0
player_animate: .byte 0
player_health: .byte 0
player_health_delta: .byte 0
player_injury: .byte 0
player_iframe: .byte 0
player_removed: .byte 0
player_state_end:

; engine
object_list_head: .byte 0
object_list_tail: .byte 0
objects_only_draw: .byte 0
sprite_space_index: .byte 0
sprite_space_avail: .byte 0
sprite_space_force: .byte 0
sprite_space_force2: .byte 0
sprite_space_force3: .byte 0
draw_picture_pointer: .word 0
draw_sprite_pointer: .word 0
draw_picture_id: .byte 0
draw_h: .byte 0
draw_v: .byte 0
draw_curr_h: .byte 0
draw_curr_v: .byte 0
draw_screen: .byte 0
draw_palette: .byte 0
random_value: .byte 0
spawn_count: .byte 0
color: .byte 0

; progress
score_low: .byte 0
score_medium: .byte 0
combo_low: .byte 0
combo_medium: .byte 0
earned_combo_low: .byte 0
earned_combo_medium: .byte 0
earned_combo_count: .byte 0
lives: .byte 0
which_level: .byte 0


.exportzp main_yield, ppu_ctrl_current, ppu_mask_current
.exportzp bg_x_scroll, bg_y_scroll, bg_nt_select
.exportzp buttons, buttons_last, buttons_press
.exportzp player_v, player_h, player_h_low, player_screen, player_dir
.exportzp player_gravity, player_gravity_low, player_render_v, player_render_h
.exportzp player_owns_swatter, player_state, player_collision_idx
.exportzp player_animate, player_health, player_health_delta
.exportzp player_injury, player_iframe, player_removed
.exportzp camera_h, camera_screen
.exportzp values, pointer
.exportzp NMI_SCROLL_target, NMI_SCROLL_strip_id, NMI_SCROLL_action
.exportzp NMI_values, NMI_pointer
.exportzp object_list_head, object_list_tail
.exportzp objects_only_draw
.exportzp sprite_space_index, sprite_space_avail
.exportzp sprite_space_force, sprite_space_force2, sprite_space_force3
.exportzp level_max_screen, level_has_entrance_door, level_has_infinite_flies
.exportzp level_player_start_v
.exportzp draw_picture_pointer, draw_sprite_pointer
.exportzp draw_picture_id, draw_h, draw_v, draw_screen, draw_palette
.exportzp draw_curr_h, draw_curr_v
.exportzp random_value, debug_mode, render_last
.exportzp spawn_count, color
.exportzp score_low, score_medium, combo_low, combo_medium
.exportzp earned_combo_low, earned_combo_medium, earned_combo_count
.exportzp spawn_index
.exportzp lives
.exportzp player_state_begin, player_state_end
.exportzp level_state_begin, level_state_end
.exportzp level_data_pointer, level_chunk_pointer
.exportzp level_table_of_contents_pointer, level_spawn_pointer
.exportzp level_complete
.exportzp which_level

collision_map = $500

.export collision_map
