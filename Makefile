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

.b/prologue.o: prologue.asm .b/resource.chr.dat .b/resource.graphics.dat \
               .b/resource.palette.dat
	ca65 -o .b/prologue.o prologue.asm -g

.b/detect_collision.o: detect_collision.asm .b/collision.dat
	ca65 -o .b/detect_collision.o detect_collision.asm -g

.b/sprites.chr.dat: sprites.png
	mkdir -p .b/
	makechr sprites.png -o .b/sprites.%s.dat -s -b 34=0f -t 8x16

.b/kitchen.chr.dat: kitchen.png
	mkdir -p .b/
	makechr kitchen.png -o .b/kitchen.%s.dat -b 0f

.b/resource.chr.dat .b/resource.graphics.dat .b/resource.palette.dat: \
            .b/sprites.chr.dat .b/kitchen.chr.dat
	head -c 4096 .b/kitchen.chr.dat > .b/resource.chr.dat
	tail -c 4096 .b/sprites.chr.dat >> .b/resource.chr.dat
	cat .b/kitchen.nametable.dat .b/kitchen.attribute.dat > \
            .b/resource.graphics.dat
	head -c 16 .b/kitchen.palette.dat > .b/resource.palette.dat
	tail -c 16 .b/sprites.palette.dat >> .b/resource.palette.dat

.b/collision.dat: collision.png
	python build_collision.py collision.png -o .b/collision.dat

filthy-kitchen.nes: $(OBJ)
	ld65 -o filthy-kitchen.nes $(OBJ) -C link.cfg -Ln filthy-kitchen.ln
	python convertln.py filthy-kitchen.ln > filthy-kitchen.nes.0.nl
