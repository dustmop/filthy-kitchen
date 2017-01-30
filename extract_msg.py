import argparse
from PIL import Image
import sys


def save_output(filename, data):
  fp = open(filename, 'wb')
  fp.write(bytearray(data))
  fp.close()


def replace_color(img, search, replace):
  width, height = img.size
  pixdata = img.load()
  for y in xrange(height):
    for x in xrange(height):
      if pixdata[x,y] == search:
        pixdata[x,y] = replace
  return img


def to_nametable(y, x):
  high = y / 8 + 0x20
  low = (y % 8) * 0x20 + x
  return high, low


def extract_msgs(input_file, alpha_font, digit_font, output_file, bg_color):
  empty = Image.new('RGB', (8,8), bg_color)
  msg_codes = []
  img = Image.open(input_file).convert('RGB')
  for k in xrange(30):
    for j in xrange(32):
      x = j * 8
      y = k * 8
      position = (x, y, x + 8, y + 8)
      tile = img.crop(position)
      tile = replace_color(tile, bg_color, (0x00, 0x00, 0x00))
      data = tile.tobytes()
      if alpha_font and data in alpha_font:
        code = alpha_font[data]
        msg_codes.append([code, k, j])
        img.paste(empty, position)
      if digit_font and data in digit_font:
        code = digit_font[data]
        msg_codes.append([code, k, j])
        img.paste(empty, position)
  img.save(output_file)
  return msg_codes


def build_msgs_file(codes, out_file):
  start = None
  pos = None
  buffer = []
  result = []
  for ch, y, x in codes:
    if pos is None:
      buffer = [ch]
      pos = (y, x)
      start = (y, x)
    elif pos == (y, x - 1):
      buffer += ch
      pos = (y, x)
    else:
      result.append([start, ''.join(buffer)])
      buffer = [ch]
      pos = (y, x)
      start = (y, x)
  result.append([start, ''.join(buffer)])
  fout = open(out_file, 'w')
  for (y, x), text in result:
    name = 'msg_' + text.replace(' ', '_').lower()
    fout.write(name + ':\n')
    high, low = to_nametable(y, x)
    fout.write('.byte $%02x,$%02x,%d,"%s"\n' % (high, low, len(text), text))
    fout.write('\n')
  fout.close()


def parse_font_img(filename, data_list):
  if filename is None:
    return None
  font = {}
  img = Image.open(filename).convert('RGB')
  for n,d in enumerate(data_list):
    x = n * 8
    glyph = img.crop((x, 0, x + 8, 8))
    font[glyph.tobytes()] = d
  return font


def parse_bg_color(text):
  total = int(text, 16)
  r = total / 0x10000
  g = (total / 0x100) % 0x100
  b = total % 0x100
  return (r, g, b)


def process(input_file, alpha_input_file, digits_input_file, output_file,
            msgs_file, bg_color_text):
  alpha_list = [chr(n + ord('A')) for n in range(26)]
  digit_list = [chr(n + ord('0')) for n in range(10)]
  alpha_font = parse_font_img(alpha_input_file, alpha_list)
  digit_font = parse_font_img(digits_input_file, digit_list)
  bg_color = parse_bg_color(bg_color_text)
  msg_codes = extract_msgs(input_file, alpha_font, digit_font, output_file,
                           bg_color)
  if msgs_file:
    build_msgs_file(msg_codes, msgs_file)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('input', type=str)
  parser.add_argument('-o', dest='output')
  parser.add_argument('-A', dest='alpha')
  parser.add_argument('-D', dest='digits')
  parser.add_argument('-m', dest='msgs')
  parser.add_argument('-b', dest='bg_color')
  args = parser.parse_args()
  process(args.input, args.alpha, args.digits, args.output, args.msgs,
          args.bg_color)


if __name__ == '__main__':
  run()
