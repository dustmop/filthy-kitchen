default: unrom

all: a53 mmc3 unrom

a53: filthy-kitchen.nes

mmc3: filthy-kitchen-mmc3.nes

unrom: filthy-kitchen-unrom.nes

clean:
	rm -rf .b/

SRC = gfx.asm \
      read_controller.asm \
      prologue.asm \
      vars.asm \
      memory_layout.asm \
      boot.asm \
      intro_outro.asm \
      marque.asm \
      fader.asm \
      gameplay.asm \
      endboss.asm \
      player.asm \
      detect_collision.asm \
      camera.asm \
      level_data.asm \
      object_list.asm \
      sprite_space.asm \
      draw_picture.asm \
      collision_data.asm \
      spawn_offscreen.asm \
      debug_display.asm \
      render_action.asm \
      hud_display.asm \
      score_combo.asm \
      fly.asm \
      swatter.asm \
      food.asm \
      explode.asm \
      points.asm \
      dirt.asm \
      utensils.asm \
      broom.asm \
      gunk_drop.asm \
      trash_gunk.asm \
      star.asm \
      wing.asm \
      toaster.asm \
      sploosh.asm \
      random.asm \
      blender.asm \
      health.asm \
      msg_catalog.asm \
      flash.asm \
      famitone.asm \
      sound.asm \
      samples.asm \
      movement.asm \
      dynamic_star_loader.asm \
      hurt_player.asm

OBJ = $(patsubst %.asm,.b/%.o,$(SRC)) .b/move_data.o

.b/%.o: %.asm
	mkdir -p .b/
	python lint_objects.py $<
	ca65 -o $@ $< -g

.b/prologue.o: prologue.asm \
            .b/resource0.compress.asm \
            .b/resource1.compress.asm \
            .b/resource2.compress.asm \
            .b/resource3.compress.asm \
            .b/resource4.compress.asm \
            .b/resource5.compress.asm \
            .b/bg_pal.dat .b/sprite_pal.dat .b/text_pal.dat \
            .b/title.palette.dat .b/title.compressed.asm \
            .b/game_over.compressed.asm \
            .b/stars.chr.dat
	ca65 -o .b/prologue.o prologue.asm -g

.b/general_mmc3.o: general_mmc3.asm
	mkdir -p .b/
	ca65 -o .b/general_mmc3.o general_mmc3.asm -g

.b/general_a53.o: general_a53.asm
	mkdir -p .b/
	ca65 -o .b/general_a53.o general_a53.asm -g

.b/draw_picture.o: draw_picture.asm .b/pictures.asm
	ca65 -o .b/draw_picture.o draw_picture.asm -g

.b/player.o: player.asm .b/pictures.h.asm
	ca65 -o .b/player.o player.asm -g

.b/hud_display.o: hud_display.asm .b/hud.compressed.asm
	ca65 -o .b/hud_display.o hud_display.asm -g

.b/level_data.o: level_data.asm .b/level1_data.asm .b/level2_data.asm .b/level3_data.asm .b/level4_data.asm
	ca65 -o .b/level_data.o level_data.asm -g

.b/fader.o: fader.asm .b/fader_pal.dat
	ca65 -o .b/fader.o fader.asm -g

.b/endboss.o: endboss.asm .b/boss.compressed.asm .b/boss.animate0.asm .b/boss.animate1.asm
	ca65 -o .b/endboss.o endboss.asm -g

.b/msg_catalog.o: msg_catalog.asm .b/hud_msg.asm .b/title_msg.asm
	ca65 -o .b/msg_catalog.o msg_catalog.asm -g

.b/music.s .b/music.dmc: music.ftm
	famitracker music.ftm -export .b/music.txt
	text2data -ca65 .b/music.txt

.b/sfx.s: sfx.ftm
	famitracker sfx.ftm -export .b/sfx.nsf
	nsf2data .b/sfx.nsf -ca65 -ntsc

.b/famitone.o: famitone.asm .b/music.s .b/sfx.s third_party/famitone2.s
	ca65 -o .b/famitone.o famitone.asm

.b/samples.o: samples.asm .b/music.dmc
	ca65 -o .b/samples.o samples.asm -g

.b/chars.chr.dat: chars.png
	mkdir -p .b/
	makechr chars.png -o .b/chars.%s.dat -s -t 8x16 --allow-overflow s

.b/chars_boss.chr.dat: chars_boss.png
	mkdir -p .b/
	makechr chars_boss.png -o .b/chars_boss.%s.dat -s -t 8x16 \
            --allow-overflow s

.b/title_chars.o: title_chars.png
	mkdir -p .b/
	makechr title_chars.png -o .b/title_chars.o -s -l

.b/title.compressed.asm: graphics_compress.py .b/title.graphics.dat
	python graphics_compress.py .b/title.graphics.dat \
            -o .b/title.compressed.asm

.b/game_over.compressed.asm: graphics_compress.py .b/game_over.graphics.dat
	python graphics_compress.py .b/game_over.graphics.dat \
            -o .b/game_over.compressed.asm

.b/hud.compressed.asm: graphics_compress.py .b/hud.nametable.dat
	python graphics_compress.py .b/hud.nametable.dat \
            -o .b/hud.compressed.asm

.b/boss.compressed.asm: graphics_compress.py .b/boss.graphics.dat
	tail -c 256 .b/boss.graphics.dat > .b/boss.floor.dat
	tail -c 832 .b/boss.graphics.dat > .b/boss.main.dat
	python graphics_compress.py .b/boss.floor.dat \
            -o .b/boss.compressed-floor.asm -n
	python graphics_compress.py .b/boss.main.dat \
            -o .b/boss.compressed-main.asm
	printf ".byte \04480,\04423,\04400\n\n" > .b/boss.compressed.asm
	cat .b/boss.compressed-floor.asm >> .b/boss.compressed.asm
	printf ".byte \04480,\04424,\044c0\n\n" >> .b/boss.compressed.asm
	cat .b/boss.compressed-main.asm >> .b/boss.compressed.asm

.b/pictures.asm .b/pictures.h.asm: pictures_player.png pictures_swatter_food.png pictures_player.info pictures_swatter_food.info .b/chars.chr.dat build_pictures.py
	python build_pictures.py -c .b/chars.chr.dat \
            -i pictures_player.info -p pictures_player.png \
            -o .b/pictures_player.asm -header .b/pictures_player.h.asm
	python build_pictures.py -c .b/chars.chr.dat \
            -i pictures_swatter_food.info -p pictures_swatter_food.png \
            -o .b/pictures_swatter_food.asm -header .b/pictures_swatter_food.h.asm
	cat .b/pictures_player.asm .b/pictures_swatter_food.asm > \
            .b/pictures.asm
	cat .b/pictures_player.h.asm .b/pictures_swatter_food.h.asm > \
            .b/pictures.h.asm

.b/title_nomsg.png .b/title_msg.asm: extract_msg.py title.png alpha.png digit.png
	python extract_msg.py title.png -A alpha.png -D digit.png \
            -o .b/title_nomsg.png -b 0078fc -m .b/title_msg.asm

.b/game_over_nomsg.png: extract_msg.py game_over.png alpha.png digit.png
	python extract_msg.py game_over.png -A alpha.png -D digit.png \
            -o .b/game_over_nomsg.png -b 0078fc

.b/hud_nomsg.png .b/hud_msg.asm: extract_msg.py hud.png alpha.png digit.png
	python extract_msg.py hud.png -A alpha.png -D digit.png \
            -o .b/hud_nomsg.png -b 000000 -m .b/hud_msg.asm

.b/title.chr.dat .b/title.palette.dat .b/title.graphics.dat .b/game_over.graphics.dat: \
            merge_chr_nt.py .b/title_nomsg.png .b/game_over_nomsg.png one.png .b/title_chars.o .b/alpha.o .b/digit.o .b/punc.o .b/title_pal.o
	mkdir -p .b/
	makechr .b/title_nomsg.png -o .b/title.o -p .b/title_pal.o
	makechr .b/game_over_nomsg.png -o .b/game_over.o -p .b/title_pal.o
	makechr one.png -o .b/one.o
	python merge_chr_nt.py .b/title.o .b/game_over.o \
            .b/one.o \
            .b/title_chars.o \
            -A .b/alpha.o \
            -D .b/digit.o \
            -P .b/punc.o \
            -c .b/title.chr.dat -p .b/title.palette.dat \
            -n .b/built%d.nametable.dat -a .b/built%d.attribute.dat
	cat .b/built00.nametable.dat .b/built00.attribute.dat > \
            .b/title.graphics.dat
	cat .b/built01.nametable.dat .b/built01.attribute.dat > \
            .b/game_over.graphics.dat

.b/hud.o: .b/hud_nomsg.png
	mkdir -p .b/
	makechr .b/hud_nomsg.png -o .b/hud.o -b 0f

.b/alpha.o: alpha.png
	mkdir -p .b/
	makechr alpha.png -o .b/alpha.o -b 0f

.b/digit.o: digit.png
	mkdir -p .b/
	makechr digit.png -o .b/digit.o -b 0f

.b/punc.o: punc.png
	mkdir -p .b/
	makechr punc.png -o .b/punc.o -b 0f

.b/boss.o: boss.png
	mkdir -p .b/
	makechr boss.png -o .b/boss.o -b 0f

.b/boss2.o: boss2.png
	mkdir -p .b/
	makechr boss2.png -o .b/boss2.o -b 0f

.b/bg_pal.o .b/bg_pal.dat: bg_pal.png
	makechr --makepal bg_pal.png -o .b/bg_pal.o
	makechr --makepal bg_pal.png -o .b/bg_pal.dat

.b/sprite_pal.o .b/sprite_pal.dat: sprite_pal.png
	makechr --makepal sprite_pal.png -o .b/sprite_pal.o
	makechr --makepal sprite_pal.png -o .b/sprite_pal.dat

.b/fader_pal.dat: bg_pal.png sprite_pal.png bg_fade_1.png sprite_fade_1.png bg_fade_2.png sprite_fade_2.png boss_pal.png
	#
	makechr --makepal bg_pal.png -o .b/bg_pal.dat
	makechr --makepal sprite_pal.png -o .b/sprite_pal.dat
	makechr --makepal bg_fade_1.png -o .b/bg_fade_1.dat
	makechr --makepal sprite_fade_1.png -o .b/sprite_fade_1.dat
	makechr --makepal bg_fade_2.png -o .b/bg_fade_2.dat
	makechr --makepal sprite_fade_2.png -o .b/sprite_fade_2.dat
	#
	makechr --makepal boss_pal.png -o .b/boss_pal.dat
	makechr --makepal sprite_pal.png -o .b/sprite_pal.dat
	cat .b/bg_pal.dat .b/sprite_pal.dat \
            .b/bg_fade_1.dat .b/sprite_fade_1.dat \
            .b/bg_fade_2.dat .b/sprite_fade_2.dat \
            .b/boss_pal.dat .b/sprite_pal.dat \
            .b/boss_pal.dat .b/sprite_pal.dat \
            .b/boss_pal.dat .b/sprite_pal.dat \
            > .b/fader_pal.dat

.b/title_pal.o: title_pal.png
	makechr --makepal title_pal.png -o .b/title_pal.o

.b/text_pal.o .b/text_pal.dat: text_pal.png
	makechr --makepal text_pal.png -o .b/text_pal.o
	makechr --makepal text_pal.png -o .b/text_pal.dat

.b/boss_pal.o .b/boss_pal.dat: boss_pal.png
	makechr --makepal boss_pal.png -o .b/boss_pal.o
	makechr --makepal boss_pal.png -o .b/boss_pal.dat

.b/level1_data.asm .b/merged_1.chr.dat .b/hud.nametable.dat .b/hud.attribute.dat:\
            build_level.py .b/hud.o bg1.png meta1.png .b/bg_pal.o \
            .b/alpha.o .b/digit.o
	python build_level.py -b bg1.png -m meta1.png -l 1 \
            -p .b/bg_pal.o -i .b/hud.o \
            -A .b/alpha.o -D .b/digit.o \
            -C ABCEHILMORSTV \
            -o .b/level1_data.asm -c .b/merged_1.chr.dat -x .b/hud.%s.dat

.b/level2_data.asm .b/merged_2.chr.dat:\
            build_level.py .b/hud.o bg2.png meta2.png .b/bg_pal.o \
            .b/alpha.o .b/digit.o
	python build_level.py -b bg2.png -m meta2.png -l 2 \
            -p .b/bg_pal.o -i .b/hud.o \
            -A .b/alpha.o -D .b/digit.o \
            -C ABCEHILMORSTV \
            -o .b/level2_data.asm -c .b/merged_2.chr.dat

.b/level3_data.asm .b/merged_2_to_3.chr.dat:\
            build_level.py .b/merged_2.chr.dat bg3.png meta3.png \
                .b/bg_pal.o
	python build_level.py -b bg3.png -m meta3.png -l 3 \
            -p .b/bg_pal.o -i .b/merged_2.chr.dat \
            -o .b/level3_data.asm -c .b/merged_2_to_3.chr.dat

.b/level4_data.asm .b/merged_2_to_4.chr.dat:\
            build_level.py .b/merged_2_to_3.chr.dat bg4.png meta4.png \
                .b/bg_pal.o
	python build_level.py -b bg4.png -m meta4.png -l 4 \
            -p .b/bg_pal.o -i .b/merged_2_to_3.chr.dat \
            -o .b/level4_data.asm -c .b/merged_2_to_4.chr.dat

.b/resource.palette.dat: .b/bg_pal.dat .b/chars.palette.dat
	head -c 16 .b/bg_pal.dat > .b/resource.palette.dat
	tail -c 16 .b/chars.palette.dat >> .b/resource.palette.dat

.b/resource0.chr.dat: .b/merged_1.chr.dat
	head -c 4096 .b/merged_1.chr.dat > .b/resource0.chr.dat

.b/resource1.chr.dat: .b/merged_2_to_4.chr.dat
	head -c 4096 .b/merged_2_to_4.chr.dat > .b/resource1.chr.dat

.b/resource2.chr.dat: .b/chars.chr.dat
	tail -c 4096 .b/chars.chr.dat > .b/resource2.chr.dat

.b/resource3.chr.dat: .b/chars_boss.chr.dat
	tail -c 4096 .b/chars_boss.chr.dat > .b/resource3.chr.dat

.b/resource4.chr.dat .b/boss.graphics.dat .b/boss.palette.dat .b/boss.animate0.asm .b/boss.animate1.asm: \
            .b/chars.chr.dat .b/hud.o .b/boss.o .b/boss2.o .b/alpha.o .b/digit.o
	python merge_chr_nt.py .b/hud.o .b/boss.o .b/boss2.o \
            -A .b/alpha.o -D .b/digit.o \
            -c .b/boss.chr.dat -n .b/boss%d.nametable.dat \
            -a .b/boss%d.attribute.dat
	cat .b/boss01.nametable.dat .b/boss01.attribute.dat > \
            .b/boss.graphics.dat
	python build_boss_delta.py \
            .b/boss01.nametable.dat .b/boss02.nametable.dat \
            -l .b/boss.animate0.asm -r .b/boss.animate1.asm
	head -c 4096 .b/boss.chr.dat > .b/resource4.chr.dat

.b/resource5.chr.dat: .b/title.chr.dat
	head -c 4096 .b/title.chr.dat > .b/resource5.chr.dat

.b/stars.chr.dat: chars_stars.png
	makechr chars_stars.png -o .b/stars.%s.dat -s -b 34 -r 0 -t 8x16

.b/resource0.compress.asm .b/resource1.compress.asm .b/resource2.compress.asm .b/resource3.compress.asm .b/resource4.compress.asm .b/resource5.compress.asm: .b/resource0.chr.dat .b/resource1.chr.dat .b/resource2.chr.dat .b/resource3.chr.dat .b/resource4.chr.dat .b/resource5.chr.dat graphics_compress.py
	python graphics_compress.py .b/resource0.chr.dat \
            -o .b/resource0.compress.asm -t
	python graphics_compress.py .b/resource1.chr.dat \
            -o .b/resource1.compress.asm -t
	python graphics_compress.py .b/resource2.chr.dat \
            -o .b/resource2.compress.asm -t
	python graphics_compress.py .b/resource3.chr.dat \
            -o .b/resource3.compress.asm -t
	python graphics_compress.py .b/resource4.chr.dat \
            -o .b/resource4.compress.asm -t
	python graphics_compress.py .b/resource5.chr.dat \
            -o .b/resource5.compress.asm -t

.b/move_data.o .b/move_data.h.asm: build_move_data.py
	mkdir -p .b/
	python build_move_data.py -a .b/move_data.asm -f .b/move_data.h.asm
	ca65 -o .b/move_data.o .b/move_data.asm

filthy-kitchen-mmc3.nes: $(OBJ) .b/general_mmc3.o link-mmc3.cfg
	ld65 -o filthy-kitchen-mmc3.nes $(OBJ) .b/general_mmc3.o \
            -C link-mmc3.cfg -Ln filthy-kitchen-mmc3.ln
	python convertln.py filthy-kitchen-mmc3.ln \
            > filthy-kitchen-mmc3.nes.0.nl
	cp filthy-kitchen-mmc3.nes.0.nl filthy-kitchen-mmc3.nes.1.nl
	cp filthy-kitchen-mmc3.nes.0.nl filthy-kitchen-mmc3.nes.2.nl
	cp filthy-kitchen-mmc3.nes.0.nl filthy-kitchen-mmc3.nes.3.nl

filthy-kitchen.nes: $(OBJ) .b/general_a53.o link-a53.cfg
	ld65 -o filthy-kitchen.nes $(OBJ) .b/general_a53.o \
            -C link-a53.cfg -Ln filthy-kitchen.ln
	python convertln.py filthy-kitchen.ln > filthy-kitchen.nes.0.nl
	cp filthy-kitchen.nes.0.nl filthy-kitchen.nes.1.nl
	cp filthy-kitchen.nes.0.nl filthy-kitchen.nes.2.nl
	cp filthy-kitchen.nes.0.nl filthy-kitchen.nes.3.nl

filthy-kitchen-unrom.nes: $(OBJ) .b/general_unrom.o link-unrom.cfg
	ld65 -o filthy-kitchen-unrom.nes $(OBJ) .b/general_unrom.o \
            -C link-unrom.cfg -Ln filthy-kitchen-unrom.ln -m map
	python convertln.py filthy-kitchen-unrom.ln \
            > filthy-kitchen-unrom.nes.0.nl
	cp filthy-kitchen-unrom.nes.0.nl filthy-kitchen-unrom.nes.1.nl
	cp filthy-kitchen-unrom.nes.0.nl filthy-kitchen-unrom.nes.2.nl
	cp filthy-kitchen-unrom.nes.0.nl filthy-kitchen-unrom.nes.3.nl
