from PIL import Image
import sys


def split(img, output_tmpl):
  size_x, size_y = img.size
  num_screens = size_x / 0x100
  for i in xrange(num_screens):
    portion = img.crop((i*0x100, 0, i*0x100 + 0x100, 0xf0))
    save_name = output_tmpl.replace('%d', '%02d' % i)
    portion.save(save_name)


def run():
  filename = sys.argv[1]
  if sys.argv[2] != '-o':
    raise RuntimeError('Expected: -o parameter')
  output_tmpl = sys.argv[3]
  if '%d' not in output_tmpl:
    raise RuntimeError('Output template must have %d in it')
  img = Image.open(filename)
  split(img, output_tmpl)


if __name__ == '__main__':
  run()
