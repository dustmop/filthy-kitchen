import argparse
from PIL import Image
import pixel_font_ocr
import sys


SPAWN_ID = 4


def convert_color(p):
  p = (p[0], p[1], p[2])
  if p == (0xfc, 0xb8, 0xfc):
    return 0
  elif p == (0xfd, 0x4d, 0x69):
    return 1
  elif p == (0x69, 0xd8, 0xfd):
    return 2
  elif p == (0xfd, 0x55, 0xfd):
    return 3
  elif p == (0x69, 0xe1, 0x69) or p == (0xd3, 0xe1, 0xd3):
    return SPAWN_ID
  else:
    raise RuntimeError('Unknown color %s' % (p,))


def save_output(filename, data):
  fp = open(filename, 'wb')
  fp.write(bytearray(data))
  fp.close()


def retrieve_spawn_data(y, x, pixels, img):
  while True:
    c = convert_color(pixels[x,y - 1])
    if c != SPAWN_ID:
      break
    y -= 1
  while True:
    c = convert_color(pixels[x - 1,y])
    if c != SPAWN_ID:
      break
    x -= 1
  tile = img.crop((x, y, x + 8, y + 8))
  num = pixel_font_ocr.read_hex(tile)
  return [y, x % 0x100, x / 0x100, num]


def color_or_add_spawn_data(y, x, pixels, img, spawn_data):
  c = convert_color(pixels[x,y])
  if c == SPAWN_ID:
    spawn_data += retrieve_spawn_data(y, x, pixels, img)
    return 0
  return c


def build_collision(img, out_collision, out_spawn):
  size_x, size_y = img.size
  collide_data = []
  spawn_data = []
  pixels = img.load()
  for chunk_x in xrange(size_x / 32):
    for block_y in xrange(size_y / 16):
      byte = 0
      for tile_x in xrange(4):
        # Top part, spawn objects and collision data.
        y = block_y * 16 + 8
        x = chunk_x * 32 + tile_x * 8
        c = color_or_add_spawn_data(y, x, pixels, img, spawn_data)
        byte |= (c << (tile_x * 2))
        # Bottom part, only check for spawn objects.
        y += 8
        if y >= size_y:
          continue
        color_or_add_spawn_data(y, x, pixels, img, spawn_data)
      collide_data.append(byte)
    collide_data.append(0xff)
  save_output(out_collision, collide_data)
  spawn_data.append(0xff)
  save_output(out_spawn, spawn_data)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('input')
  parser.add_argument('-c', dest='collision')
  parser.add_argument('-s', dest='spawn')
  args = parser.parse_args()
  img = Image.open(args.input)
  build_collision(img, args.collision, args.spawn)


if __name__ == '__main__':
  run()
