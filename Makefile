default: filthy-kitchen.nes

clean:
	rm -rf .b/

SRC = gfx.asm \
      read_controller.asm \
      prologue.asm \
      vars.asm \
      general_mmc3.asm \
      boot.asm \
      intro_outro.asm \
      gameplay.asm \
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
      star.asm \
      random.asm \
      health.asm \
      msg_catalog.asm \
      flash.asm \
      famitone.asm

OBJ = $(patsubst %.asm,.b/%.o,$(SRC)) .b/trig.o

.b/%.o: %.asm
	mkdir -p .b/
	python lint_objects.py $<
	ca65 -o $@ $< -g

.b/prologue.o: prologue.asm .b/resource.chr.dat .b/title.chr.dat \
            .b/bg_pal.dat .b/sprite_pal.dat \
            .b/title.palette.dat .b/title.compressed.asm \
            .b/game_over.compressed.asm
	ca65 -o .b/prologue.o prologue.asm -g

.b/draw_picture.o: draw_picture.asm .b/pictures.asm
	ca65 -o .b/draw_picture.o draw_picture.asm -g

.b/player.o: player.asm .b/pictures.h.asm
	ca65 -o .b/player.o player.asm -g

.b/hud_display.o: hud_display.asm .b/hud.compressed.asm
	ca65 -o .b/hud_display.o hud_display.asm -g

.b/level_data.o: level_data.asm .b/level1_data.asm .b/level9_data.asm
	ca65 -o .b/level_data.o level_data.asm -g

.b/fly.o: fly.asm .b/trig.h.asm
	ca65 -o .b/fly.o fly.asm -g

.b/msg_catalog.o: msg_catalog.asm .b/hud_msg.asm .b/title_msg.asm
	ca65 -o .b/msg_catalog.o msg_catalog.asm -g

.b/famitone.o: famitone.asm music.ftm third_party/famitone2.s
	famitracker music.ftm -export .b/music.txt
	text2data -ca65 .b/music.txt
	ca65 -o .b/famitone.o famitone.asm

.b/chars.chr.dat: chars.png
	mkdir -p .b/
	makechr chars.png -o .b/chars.%s.dat -s -b 34=0f -t 8x16 \
            --allow-overflow s

.b/title.compressed.asm: graphics_compress.py .b/title.graphics.dat
	python graphics_compress.py .b/title.graphics.dat \
            -o .b/title.compressed.asm

.b/game_over.compressed.asm: graphics_compress.py .b/game_over.graphics.dat
	python graphics_compress.py .b/game_over.graphics.dat \
            -o .b/game_over.compressed.asm

.b/hud.compressed.asm: graphics_compress.py .b/hud.nametable.dat
	python graphics_compress.py .b/hud.nametable.dat \
            -o .b/hud.compressed.asm

.b/pictures.asm .b/pictures.h.asm: pictures.png pictures.info .b/chars.chr.dat build_pictures.py
	python build_pictures.py -i pictures.info -p pictures.png \
            -c .b/chars.chr.dat -o .b/pictures.asm -header .b/pictures.h.asm

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
            merge_chr_nt.py .b/title_nomsg.png .b/game_over_nomsg.png .b/alpha.o .b/digit.o .b/title_pal.o
	mkdir -p .b/
	makechr .b/title_nomsg.png -o .b/title.o -p .b/title_pal.o
	makechr .b/game_over_nomsg.png -o .b/game_over.o -p .b/title_pal.o
	python merge_chr_nt.py .b/title.o .b/game_over.o \
            -A .b/alpha.o \
            -D .b/digit.o \
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

.b/bg_pal.o .b/bg_pal.dat: bg_pal.png
	makechr --makepal bg_pal.png -o .b/bg_pal.o
	makechr --makepal bg_pal.png -o .b/bg_pal.dat

.b/sprite_pal.o .b/sprite_pal.dat: sprite_pal.png
	makechr --makepal sprite_pal.png -o .b/sprite_pal.o
	makechr --makepal sprite_pal.png -o .b/sprite_pal.dat

.b/title_pal.o: title_pal.png
	makechr --makepal title_pal.png -o .b/title_pal.o

.b/level1_data.asm .b/merged_1.chr.dat .b/hud.nametable.dat .b/hud.attribute.dat:\
            build_level.py .b/hud.o bg1.png meta1.png .b/bg_pal.o \
            .b/alpha.o .b/digit.o
	python build_level.py -b bg1.png -m meta1.png -l 1 \
            -p .b/bg_pal.o -i .b/hud.o \
            -A .b/alpha.o -D .b/digit.o \
            -o .b/level1_data.asm -c .b/merged_1.chr.dat -x .b/hud.%s.dat

.b/level2_data.asm .b/merged_1_to_2.chr.dat:\
            build_level.py .b/merged_1.chr.dat bg2.png meta2.png .b/bg_pal.o
	python build_level.py -b bg2.png -m meta2.png -l 2 \
            -p .b/bg_pal.o -i .b/merged_1.chr.dat \
            -o .b/level2_data.asm -c .b/merged_1_to_2.chr.dat

.b/level9_data.asm .b/merged_1_to_9.chr.dat:\
            build_level.py .b/merged_1_to_2.chr.dat bg9.png meta9.png .b/bg_pal.o
	python build_level.py -b bg9.png -m meta9.png -l 9 \
            -p .b/bg_pal.o -i .b/merged_1_to_2.chr.dat \
            -o .b/level9_data.asm -c .b/merged_1_to_9.chr.dat

.b/resource.chr.dat .b/resource.palette.dat: \
            .b/chars.chr.dat .b/merged_1_to_9.chr.dat .b/bg_pal.dat
	head -c 4096 .b/merged_1_to_9.chr.dat > .b/resource.chr.dat
	tail -c 4096 .b/chars.chr.dat >> .b/resource.chr.dat
	head -c 16 .b/bg_pal.dat > .b/resource.palette.dat
	tail -c 16 .b/chars.palette.dat >> .b/resource.palette.dat

.b/trig.o .b/trig.h.asm: build_trig.py
	mkdir -p .b/
	python build_trig.py -a .b/trig.asm -f .b/trig.h.asm
	ca65 -o .b/trig.o .b/trig.asm

filthy-kitchen.nes: $(OBJ) link.cfg
	ld65 -o filthy-kitchen.nes $(OBJ) -C link.cfg -Ln filthy-kitchen.ln
	python convertln.py filthy-kitchen.ln > filthy-kitchen.nes.0.nl
	cp filthy-kitchen.nes.0.nl filthy-kitchen.nes.1.nl
	cp filthy-kitchen.nes.0.nl filthy-kitchen.nes.2.nl
	cp filthy-kitchen.nes.0.nl filthy-kitchen.nes.3.nl
