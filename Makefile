default: filthy-kitchen.nes

clean:
	rm -rf .b/

SRC = gfx.asm \
      read_controller.asm \
      prologue.asm \
      vars.asm \
      general_mmc3.asm \
      boot.asm \
      intro.asm \
      gameplay.asm \
      player.asm \
      detect_collision.asm \
      camera.asm \
      level_data.asm \
      object_list.asm \
      sprite_space.asm \
      draw_picture.asm \
      collision_data.asm \
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
      random.asm \
      health.asm \
      msg_catalog.asm

OBJ = $(patsubst %.asm,.b/%.o,$(SRC)) .b/trig.o

.b/%.o: %.asm
	mkdir -p .b/
	python lint_objects.py $<
	ca65 -o $@ $< -g

.b/prologue.o: prologue.asm .b/resource.chr.dat .b/title.chr.dat \
            .b/bg_pal.dat .b/sprite_pal.dat \
            .b/title.palette.dat
	ca65 -o .b/prologue.o prologue.asm -g

.b/draw_picture.o: draw_picture.asm .b/pictures.asm
	ca65 -o .b/draw_picture.o draw_picture.asm -g

.b/player.o: player.asm .b/pictures.h.asm
	ca65 -o .b/player.o player.asm -g

.b/hud_display.o: hud_display.asm .b/hud.nametable.dat
	ca65 -o .b/hud_display.o hud_display.asm -g

.b/level_data.o: level_data.asm .b/level_data.dat
	ca65 -o .b/level_data.o level_data.asm -g

.b/fly.o: fly.asm .b/trig.h.asm
	ca65 -o .b/fly.o fly.asm -g

.b/msg_catalog.o: msg_catalog.asm .b/hud_msg.asm .b/title_msg.asm
	ca65 -o .b/msg_catalog.o msg_catalog.asm -g

.b/chars.chr.dat: chars.png
	mkdir -p .b/
	makechr chars.png -o .b/chars.%s.dat -s -b 34=0f -t 8x16 \
            --allow-overflow s

.b/pictures.asm .b/pictures.h.asm: pictures.png pictures.info .b/chars.chr.dat build_pictures.py
	python build_pictures.py -i pictures.info -p pictures.png \
            -c .b/chars.chr.dat -o .b/pictures.asm -header .b/pictures.h.asm

.b/title_nomsg.png .b/title_msg.asm: extract_msg.py title.png alpha.png digit.png
	python extract_msg.py title.png -A alpha.png -D digit.png \
            -o .b/title_nomsg.png -b 0078fc -m .b/title_msg.asm

.b/hud_nomsg.png .b/hud_msg.asm: extract_msg.py hud.png alpha.png digit.png
	python extract_msg.py hud.png -A alpha.png -D digit.png \
            -o .b/hud_nomsg.png -b 000000 -m .b/hud_msg.asm

.b/title.chr.dat .b/title.palette.dat .b/title.graphics.dat: \
            merge_chr_nt.py .b/title_nomsg.png .b/alpha.o .b/digit.o .b/title_pal.o
	mkdir -p .b/
	makechr .b/title_nomsg.png -o .b/title.o -p .b/title_pal.o
	python merge_chr_nt.py .b/title.o \
            -A .b/alpha.o \
            -D .b/digit.o \
            -c .b/title.chr.dat -p .b/title.palette.dat \
            -n .b/title.nametable.dat -a .b/title.attribute.dat
	cat .b/title.nametable.dat .b/title.attribute.dat > \
            .b/title.graphics.dat

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

.b/kitchen.chr.dat .b/kitchen.nametable00.dat .b/hud.nametable.dat: \
            merge_chr_nt.py entire-level.png .b/hud.o .b/alpha.o .b/digit.o \
            .b/bg_pal.o
	mkdir -p .b/
	python split_level.py entire-level.png -o .b/screen%d.png
	makechr .b/screen00.png -o .b/screen00.o -b 0f -p .b/bg_pal.o
	makechr .b/screen01.png -o .b/screen01.o -b 0f -p .b/bg_pal.o
	makechr .b/screen02.png -o .b/screen02.o -b 0f -p .b/bg_pal.o
	makechr .b/screen03.png -o .b/screen03.o -b 0f -p .b/bg_pal.o
	python merge_chr_nt.py .b/screen00.o .b/screen01.o \
            .b/screen02.o .b/screen03.o .b/hud.o \
            -A .b/alpha.o \
            -D .b/digit.o \
            -c .b/kitchen.chr.dat -p .b/kitchen.palette.dat \
            -n .b/kitchen.nametable%d.dat -a .b/kitchen.attribute%d.dat
	mv .b/kitchen.attribute04.dat .b/hud.attribute.dat
	head -c 192 .b/kitchen.nametable04.dat > .b/hud.nametable.dat
	rm .b/kitchen.nametable04.dat

.b/level_data.dat: build_level_data.py .b/kitchen.nametable00.dat \
                   .b/bg_meta.dat
	python build_level_data.py -n .b/kitchen.nametable%d.dat \
            -a .b/kitchen.attribute%d.dat -m .b/bg_meta.dat \
            -o .b/level_data%s.dat -t .b/level_data.txt

.b/resource.chr.dat .b/resource.palette.dat: \
            .b/chars.chr.dat .b/kitchen.chr.dat
	head -c 4096 .b/kitchen.chr.dat > .b/resource.chr.dat
	tail -c 4096 .b/chars.chr.dat >> .b/resource.chr.dat
	head -c 16 .b/kitchen.palette.dat > .b/resource.palette.dat
	tail -c 16 .b/chars.palette.dat >> .b/resource.palette.dat

.b/bg_meta.dat: build_collision.py bg_meta.png
	python build_collision.py bg_meta.png -o .b/bg_meta.dat

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
