from PIL import Image
import sys


def convert_color(p):
  p = (p[0], p[1], p[2])
  if p == (0xfc, 0xb8, 0xfc):
    return 0
  elif p == (0xfd, 0x4d, 0x69):
    return 1
  else:
    raise RuntimeError('Unknown color %s' % (p,))


def save_output(filename, data):
  fp = open(filename, 'wb')
  fp.write(bytearray(data))
  fp.close()


def build_collision(img, out_name):
  accum = []
  pixels = img.load()
  for block_y in xrange(15):
    byte = 0
    for tile_x in xrange(32):
      y = block_y * 16 + 8
      x = tile_x * 8
      c = convert_color(pixels[x,y])
      offset = tile_x % 8
      byte |= (c << offset)
      if offset == 7:
        # flush
        accum.append(byte)
        byte = 0
  save_output(out_name, accum)


def run():
  filename = sys.argv[1]
  if sys.argv[2] != '-o':
    raise RuntimeError('Expected: -o output parameter')
  out_name = sys.argv[3]
  img = Image.open(filename)
  build_collision(img, out_name)


if __name__ == '__main__':
  run()
