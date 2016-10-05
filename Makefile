default: filthy-kitchen.nes

clean:
	rm -rf .b/

SRC = main.asm \
      gfx.asm \
      read_controller.asm \
      prologue.asm \
      vars.asm \
      player.asm

OBJ = $(patsubst %.asm,.b/%.o,$(SRC))

.b/%.o: %.asm
	mkdir -p .b/
	ca65 -o $@ $(patsubst .b/%.o, %.asm, $@) -g

.b/prologue.o: prologue.asm .b/resource.chr.dat .b/resource.graphics.dat \
               .b/resource.palette.dat
	ca65 -o .b/prologue.o prologue.asm -g

.b/human.chr.dat: human.png
	mkdir -p .b/
	makechr human.png -o .b/human.%s.dat -s -b 30=0f -t 8x16

.b/kitchen.chr.dat: kitchen.png
	mkdir -p .b/
	makechr kitchen.png -o .b/kitchen.%s.dat -b 0f

.b/resource.chr.dat .b/resource.graphics.dat .b/resource.palette.dat: \
            .b/human.chr.dat .b/kitchen.chr.dat
	head -c 4096 .b/kitchen.chr.dat > .b/resource.chr.dat
	tail -c 4096 .b/human.chr.dat >> .b/resource.chr.dat
	cat .b/kitchen.nametable.dat .b/kitchen.attribute.dat > \
            .b/resource.graphics.dat
	head -c 16 .b/kitchen.palette.dat > .b/resource.palette.dat
	tail -c 16 .b/human.palette.dat >> .b/resource.palette.dat

filthy-kitchen.nes: $(OBJ)
	ld65 -o filthy-kitchen.nes $(OBJ) -C link.cfg -Ln filthy-kitchen.ln
	python convertln.py filthy-kitchen.ln > filthy-kitchen.nes.0.nl
