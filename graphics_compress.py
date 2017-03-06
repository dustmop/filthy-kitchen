import argparse
import math


class GraphicsCompressor(object):
  def init(self):
    self.state = None
    self.size = 0
    self.buffer = bytearray()
    self.prev = None
    self.commands = []

  def compress(self, data):
    self.init()
    for byte in data:
      if self.prev is None:
        self.new_literal(byte)
      elif self.state == 'same':
        self.same_state(byte)
      elif self.state == 'inc':
        self.inc_state(byte)
      else: # self.state == 'literal'
        self.literal_state(byte)
      self.prev = byte
    self.flush()

  def same_state(self, byte):
    if byte == self.prev:
      self.size += 1
      return
    self.flush()
    self.new_literal(byte)

  def inc_state(self, byte):
    if ord(byte) == ord(self.prev) + 1:
      self.size += 1
      return
    self.flush()
    self.new_literal(byte)

  def literal_state(self, byte):
    if byte == self.prev:
      self.pull_one_flush()
      self.state = 'same'
      self.size = 2
      self.buffer = bytearray([self.prev])
    elif ord(byte) == ord(self.prev) + 1:
      self.pull_one_flush()
      self.state = 'inc'
      self.size = 2
      self.buffer = bytearray([self.prev])
    else:
      self.state = 'literal'
      self.size += 1
      self.buffer.append(byte)

  def new_literal(self, byte):
    self.state = 'literal'
    self.size = 1
    self.buffer = bytearray([byte])

  def pull_one_flush(self):
    self.buffer = self.buffer[:-1]
    self.size -= 1
    self.flush()

  def flush(self):
    while self.size > 0:
      if self.size <= 63:
        self.commands.append([self.state, self.size, self.buffer])
        break
      self.commands.append([self.state, 63, self.buffer])
      self.size -= 63
    self.buffer = bytearray()
    self.size = 0

  def to_bytes(self):
    accum = []
    for kind, size, data in self.commands:
      if kind == 'same':
        accum.append(0x80 | size)
        accum.append(data[0])
      elif kind == 'inc':
        accum.append(0x40 | size)
        accum.append(data[0])
      elif kind == 'literal':
        accum.append(0x00 | size)
        accum += data
    return accum


def trim_ending(data):
  i = len(data) - 1
  while i > 0:
    if ord(data[i]) != 0:
      end = int(math.ceil((i + 1) / 32.0) * 32 + 1)
      return data[0:end]
    i -= 1
  return data


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('input')
  parser.add_argument('-o', dest='output')
  parser.add_argument('-n', dest='no_null', action='store_true')
  parser.add_argument('-t', dest='trim', action='store_true')
  args = parser.parse_args()
  fp = open(args.input, 'r')
  content = fp.read()
  fp.close()
  if args.trim:
    content = trim_ending(content)
  compressor = GraphicsCompressor()
  compressor.compress(content)
  fout = open(args.output, 'w')
  count = 0
  for kind, size, data in compressor.commands:
    if kind == 'same':
      fout.write('.byte $%02x\n' % (0x80 | size))
      count += 1
    elif kind == 'inc':
      fout.write('.byte $%02x\n' % (0x40 | size))
      count += 1
    elif kind == 'literal':
      fout.write('.byte $%02x\n' % (0x00 | size))
      count += 1
    fout.write('.byte %s\n' % ','.join('$%02x' % b for b in data))
    count += len(data)
    fout.write('\n')
  if not args.no_null:
    fout.write('.byte $00\n')
    count += 1
  fout.write('; %d\n' % count)
  fout.close()


if __name__ == '__main__':
  run()
