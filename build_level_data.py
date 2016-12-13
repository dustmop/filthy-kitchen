import argparse
import os


"""
Build level_data, composed of vertical strips.

Each strip contains four lists:
Nametable updates, 4 at a time, each 1 tile wide.
Attribute data, 2 blocks wide, a byte at a time.
Collision data, 4 tiles wide, a byte at a time.

Strips are stored in a table. Each element has a strip id, which is the index
into the table.

Levels are just lists of strip ids.

In the future, certain parts of this layout may be run-length encoded.
"""


def save_output(filename, data):
  fp = open(filename, 'wb')
  fp.write(bytearray(data))
  fp.close()


def fill_template(template, param):
  if '%d' in template:
    return template.replace('%d', '%02d' % param)
  elif '%s' in template:
    return template.replace('%s', '%s' % param)


class LevelDataBuilder(object):
  def __init__(self):
    self.nt_column = []
    self.attribute = []
    self.collision = []

  def add_nametable(self, nametable):
    # Nametable has 8 chunks across.
    # Each chunk has 4 tiles across, and 30 tiles down.
    for chunk_x in xrange(8):
      nt_column = []
      for tile_x in xrange(4):
        x = chunk_x*4 + tile_x
        for y in xrange(30):
          nt_column.append(ord(nametable[y*0x20 + x]))
        nt_column += [0] * 2
      # Each element is 128 bytes.
      self.nt_column.append(nt_column)

  def add_attribute(self, attribute):
    # Attributes has 8 chunks across.
    for x in xrange(8):
      attr_column = []
      for y in xrange(8):
        byte = attribute[y*8 + x]
        attr_column.append(ord(byte))
      # Each element is 8 bytes.
      self.attribute.append(attr_column)

  def add_collision(self, collision):
    num = len(collision) / 16
    for i in xrange(num):
      bytes = collision[i*16:i*16 + 16]
      # Each element is 16 bytes.
      self.collision.append(bytes)

  def create(self, output_tmpl, output_text):
    assert len(self.nt_column) == len(self.attribute) == len(self.collision)
    self.cache = {}
    self.struct_idx = 0
    self.level_data = []
    self.struct_nt_column = []
    self.struct_attribute = []
    self.struct_collision = []
    num = len(self.nt_column)
    for k in xrange(num):
      key = str(bytearray(self.nt_column[k]) + bytearray(self.attribute[k]) +
                bytearray(self.collision[k]))
      if key in self.cache:
        id = self.cache[key]
      else:
        id = self.struct_idx
        self.struct_idx += 1
        self.struct_nt_column += self.nt_column[k]
        self.struct_attribute += self.attribute[k]
        self.struct_collision += self.collision[k]
        self.cache[key] = id
      self.level_data.append(id)
    fp = open(fill_template(output_tmpl, ''), 'w')
    fp.write(bytearray(self.level_data))
    fp.close()
    fp = open(fill_template(output_tmpl, '_nt_column'), 'w')
    fp.write(bytearray(self.struct_nt_column))
    fp.close()
    fp = open(fill_template(output_tmpl, '_attribute'), 'w')
    fp.write(bytearray(self.struct_attribute))
    fp.close()
    fp = open(fill_template(output_tmpl, '_collision'), 'w')
    fp.write(bytearray(self.struct_collision))
    fp.close()
    fp = open(output_text, 'w')
    fp.write('level_data:\n')
    self.write_slices(fp, self.level_data, 8)
    fp.write('level_data_nt_column:\n')
    self.write_slices(fp, self.struct_nt_column, 128)
    fp.write('level_data_attribute:\n')
    self.write_slices(fp, self.struct_attribute, 8)
    fp.write('level_data_collision:\n')
    self.write_slices(fp, [ord(n) for n in self.struct_collision], 16)
    fp.close()

  def write_slices(self, fp, data, size):
    for i in xrange(len(data) / size):
      slice = data[i*size:i*size + size]
      fp.write('%s\n' % ','.join('%02x' % d for d in slice))
    fp.write('\n')


def get_bytes(template, i):
  filename = fill_template(template, i)
  if not os.path.isfile(filename):
    return None
  fp = open(filename, 'rb')
  bytes = fp.read()
  fp.close()
  return bytes


def pad_hud_on_top(data):
  data = bytearray(data)
  for i in xrange(8):
    data[i + 0] = 0x55
    data[i + 8] = (data[i + 8] & 0xf0) | 0x05
  return bytes(data)


def process(nametable_tmpl, attribute_tmpl, collision_file,
            output_tmpl, output_text):
  builder = LevelDataBuilder()
  i = 0
  while True:
    nametable = get_bytes(nametable_tmpl, i)
    if not nametable:
      break
    builder.add_nametable(nametable)
    attribute = get_bytes(attribute_tmpl, i)
    builder.add_attribute(pad_hud_on_top(attribute))
    i += 1
  fp = open(collision_file, 'rb')
  bytes = fp.read()
  fp.close()
  builder.add_collision(bytes)
  builder.create(output_tmpl, output_text)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('-n', dest='nametable_tmpl')
  parser.add_argument('-a', dest='attribute_tmpl')
  parser.add_argument('-c', dest='collision_file')
  parser.add_argument('-o', dest='output_tmpl')
  parser.add_argument('-t', dest='output_text')
  args = parser.parse_args()
  process(args.nametable_tmpl, args.attribute_tmpl, args.collision_file,
          args.output_tmpl, args.output_text)


if __name__ == '__main__':
  run()
