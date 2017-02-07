import argparse


def read_file(filename):
  fp = open(filename, 'r')
  content = fp.read()
  fp.close()
  return content


def is_next_pos(prev_y, prev_x, y, x):
  if prev_y is None or prev_x is None:
    return False
  if y == prev_y and x == prev_x + 1:
    return True
  if y == prev_y + 1 and x == 0 and prev_x == 31:
    return True
  return False


def write_addr(fout, byte):
  if byte == 0:
    fout.write('sty PPU_ADDR\n')
  elif byte == 0x25:
    fout.write('stx PPU_ADDR\n')
  else:
    fout.write('mov PPU_ADDR, #$%02x\n' % byte)


def write_data(fout, byte):
  if byte == 0:
    fout.write('sty PPU_DATA\n')
  elif byte == 0x25:
    fout.write('stx PPU_DATA\n')
  else:
    fout.write('mov PPU_DATA, #$%02x\n' % byte)


def create_deltas(left, rite, fpl, fpr):
  n = 0
  prev_y = None
  prev_x = None
  fpl.write('ldy #$00\n')
  fpr.write('ldy #$00\n')
  fpl.write('ldx #$25\n')
  fpr.write('ldx #$25\n')
  for y in xrange(30):
    for x in xrange(32):
      pos = y * 32 + x
      a = ord(left[pos])
      b = ord(rite[pos])
      if a == b:
        continue
      if not is_next_pos(prev_y, prev_x, y, x):
        high = y / 8 + 0x24
        low = (y % 8) * 0x20 + x
        write_addr(fpl, high)
        write_addr(fpr, high)
        write_addr(fpl, low)
        write_addr(fpr, low)
      write_data(fpl, a)
      write_data(fpr, b)
      prev_y = y
      prev_x = x
  fpl.write('rts\n')
  fpr.write('rts\n')


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('input', nargs='+')
  parser.add_argument('-l', dest='out_left')
  parser.add_argument('-r', dest='out_right')
  args = parser.parse_args()
  left = read_file(args.input[0])
  rite = read_file(args.input[1])
  fpl = open(args.out_left, 'w')
  fpr = open(args.out_right, 'w')
  create_deltas(left, rite, fpl, fpr)
  fpl.close()
  fpr.close()


if __name__ == '__main__':
  run()
