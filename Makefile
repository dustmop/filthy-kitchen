default: filthy-kitchen.nes

clean:
	rm -rf .b/

SRC = main.asm \
      gfx.asm \
      read_controller.asm \
      prologue.asm \
      vars.asm \
      player.asm \
      detect_collision.asm

OBJ = $(patsubst %.asm,.b/%.o,$(SRC))

.b/%.o: %.asm
	mkdir -p .b/
	ca65 -o $@ $(patsubst .b/%.o, %.asm, $@) -g

.b/prologue.o: prologue.asm .b/resource.chr.dat .b/resource.palette.dat \
               .b/resource.graphics00.dat .b/resource.graphics01.dat
	ca65 -o .b/prologue.o prologue.asm -g

.b/detect_collision.o: detect_collision.asm .b/collision.dat
	ca65 -o .b/detect_collision.o detect_collision.asm -g

.b/sprites.chr.dat: sprites.png
	mkdir -p .b/
	makechr sprites.png -o .b/sprites.%s.dat -s -b 34=0f -t 8x16

.b/kitchen.chr.dat .b/resource.graphics00.dat .b/resource.graphics01.dat: \
            entire-level.png
	mkdir -p .b/
	python split_level.py entire-level.png -o .b/screen%d.png
	makechr .b/screen00.png -o .b/screen00.o -b 0f
	makechr .b/screen01.png -o .b/screen01.o -b 0f
	makechr .b/screen02.png -o .b/screen02.o -b 0f
	makechr .b/screen03.png -o .b/screen03.o -b 0f
	python merge_chr_nt.py .b/screen00.o .b/screen01.o \
            .b/screen02.o .b/screen03.o \
            -c .b/kitchen.chr.dat -p .b/kitchen.palette.dat \
            -g .b/resource.graphics%d.dat

.b/resource.chr.dat .b/resource.palette.dat: \
            .b/sprites.chr.dat .b/kitchen.chr.dat
	head -c 4096 .b/kitchen.chr.dat > .b/resource.chr.dat
	tail -c 4096 .b/sprites.chr.dat >> .b/resource.chr.dat
	head -c 16 .b/kitchen.palette.dat > .b/resource.palette.dat
	tail -c 16 .b/sprites.palette.dat >> .b/resource.palette.dat

.b/collision.dat: collision.png
	python build_collision.py collision.png -o .b/collision.dat

filthy-kitchen.nes: $(OBJ)
	ld65 -o filthy-kitchen.nes $(OBJ) -C link.cfg -Ln filthy-kitchen.ln
	python convertln.py filthy-kitchen.ln > filthy-kitchen.nes.0.nl
