from PIL import Image
import sys


def convert_color(p):
  p = (p[0], p[1], p[2])
  if p == (0xfc, 0xb8, 0xfc):
    return 0
  elif p == (0xfd, 0x4d, 0x69):
    return 1
  elif p == (0x69, 0xd8, 0xfd):
    return 2
  elif p == (0x69, 0xe1, 0x69) or p == (0xd3, 0xe1, 0xd3):
    # TODO: Process object metadata.
    return 0
  else:
    raise RuntimeError('Unknown color %s' % (p,))


def save_output(filename, data):
  fp = open(filename, 'wb')
  fp.write(bytearray(data))
  fp.close()


def build_collision(img, out_name):
  size_x, size_y = img.size
  accum = []
  pixels = img.load()
  for chunk_x in xrange(size_x / 32):
    for block_y in xrange(size_y / 16):
      byte = 0
      for tile_x in xrange(4):
        y = block_y * 16 + 8
        x = chunk_x * 32 + tile_x * 8
        c = convert_color(pixels[x,y])
        byte |= (c << (tile_x * 2))
      accum.append(byte)
    accum.append(0xff)
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
