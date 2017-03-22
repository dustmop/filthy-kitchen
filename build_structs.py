import argparse
import collections
import graphics_compress
import math
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


def read_file(filename):
  fp = open(filename, 'rb')
  bytes = fp.read()
  fp.close()
  return bytes


class WorldCollection(object):
  """Collect data from binary files"""
  def __init__(self):
    self.nt_column = []
    self.attribute = []
    self.collision = []
    self.spawn = {}
    self.size = None
    self.compressor = graphics_compress.GraphicsCompressor()

  def add_nametable(self, nametable):
    # Nametable has 8 chunks across.
    # Each chunk has 4 tiles across, and 30 tiles down.
    for chunk_x in xrange(8):
      for tile_x in xrange(4):
        nt_column = []
        x = chunk_x*4 + tile_x
        for y in xrange(6,30):
          nt_column.append(ord(nametable[y*0x20 + x]))
        # Each element is 24 bytes.
        self.compressor.compress([chr(e) for e in nt_column[:-2]])
        bytes = self.compressor.to_bytes()
        self.nt_column.append(bytes)

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
      bytes = [ord(d) for d in collision[i*16:i*16 + 16]]
      # Each element is 16 bytes.
      self.collision.append(bytes)

  def add_spawn(self, spawn):
    k = 0
    while ord(spawn[k]) != 0xff:
      y = ord(spawn[k])
      x = ord(spawn[k+1])
      w = ord(spawn[k+2])
      id = ord(spawn[k+3])
      offset = x / 0x20 + (w * 8)
      if not offset in self.spawn:
        self.spawn[offset] = []
      self.spawn[offset] += [y, x, w, id]
      k += 4

  def done(self):
    assert (len(self.nt_column) == (len(self.attribute)*4) ==
            (len(self.collision)*4))
    self.size = len(self.attribute)


class LevelDataBuilder(object):
  """Store structured data from world collection"""

  def create(self, collect):
    self.init()
    self.last_screen = (collect.size / 8) - 1
    for k in xrange(collect.size):
      nt0 = self.store_nt(collect.nt_column[k*4+0])
      nt1 = self.store_nt(collect.nt_column[k*4+1])
      nt2 = self.store_nt(collect.nt_column[k*4+2])
      nt3 = self.store_nt(collect.nt_column[k*4+3])
      attr = self.store_attr(collect.attribute[k])
      col = self.store_collision(collect.collision[k])
      spawn = self.store_spawn(collect.spawn.get(k))
      id = self.store_chunk(nt0, nt1, nt2, nt3,
                            attr, col, spawn)
      self.level_data.append(id)

  def init(self):
    self.level_data = []
    self.nt_lookup = {}
    self.nt_compress = []
    self.attribute = collections.OrderedDict()
    self.collision = collections.OrderedDict()
    self.spawn = collections.OrderedDict()
    self.chunks = collections.OrderedDict()

  def store_nt(self, data):
    SLICE_SIZE = 8
    key = bytes(bytearray(data))
    if not key in self.nt_lookup:
      index = len(self.nt_compress) / SLICE_SIZE
      for i in xrange(int(math.ceil(len(data) * 1.0 / SLICE_SIZE))):
        slice = data[i*SLICE_SIZE: i*SLICE_SIZE+SLICE_SIZE]
        slice += [0xff]*(SLICE_SIZE - len(slice))
        self.nt_compress += slice
      self.nt_lookup[key] = index
    return self.nt_lookup[key]

  def store_attr(self, data):
    return self._intern(self.attribute, data)

  def store_collision(self, data):
    return self._intern(self.collision, data)

  def store_spawn(self, data):
    if not data:
      return 0xff
    return self._intern(self.spawn, data)

  def store_chunk(self, nt0, nt1, nt2, nt3, attr, col, spawn):
    data = [nt0, nt1, nt2, nt3, attr, col, spawn, 0xff]
    return self._intern(self.chunks, data)

  def _intern(self, storage, data):
    key = bytes(bytearray(data))
    if not key in storage:
      storage[key] = len(storage)
    return storage[key]

  def save_text(self, level, output_file):
    if not level:
      raise RuntimeError('Need level, got %s' % level)
    fp = open(output_file, 'w')
    fp.write('LEVEL%s_LAST_SCREEN = %s\n' % (level, self.last_screen))
    fp.write('\n')
    fp.write('level%s_data:\n' % level)
    self.write_slices(fp, self.level_data, 8)
    fp.write('level%s_chunk:\n' % level)
    self.write_slices(fp, self.storage_bytes(self.chunks), 8)
    fp.write('level%s_table_of_contents:\n' % level)
    fp.write('.word level%s_nt_compress\n' % level)
    fp.write('.word level%s_attribute\n' % level)
    fp.write('.word level%s_collision\n' % level)
    fp.write('\n')
    fp.write('level%s_nt_compress:\n' % level)
    self.write_slices(fp, self.nt_compress, 8)
    fp.write('level%s_attribute:\n' % level)
    self.write_slices(fp, self.storage_bytes(self.attribute), 8)
    fp.write('level%s_collision:\n' % level)
    self.write_slices(fp, self.storage_bytes(self.collision), 16)
    fp.write('level%s_spawn:\n' % level)
    self.write_slices(fp, self.storage_bytes(self.spawn, [0xff]), 4)
    fp.close()

  def storage_bytes(self, storage, suffix=None):
    accum = []
    for data in storage.keys():
      accum += data
    if suffix:
      accum += suffix
    return bytearray(accum)

  def write_slices(self, fp, data, size):
    for i in xrange(len(data) / size):
      slice = data[i*size:i*size + size]
      fp.write('.byte %s\n' % ','.join('$%02x' % d for d in slice))
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


def process(init_count, nametable_tmpl, attribute_tmpl, collision_file,
            spawn_file, output_tmpl, output_level, output_text):
  world = WorldCollection()
  i = int(init_count)
  while True:
    nametable = get_bytes(nametable_tmpl, i)
    if not nametable:
      break
    world.add_nametable(nametable)
    attribute = get_bytes(attribute_tmpl, i)
    world.add_attribute(pad_hud_on_top(attribute))
    i += 1
  world.add_collision(read_file(collision_file))
  world.add_spawn(read_file(spawn_file))
  world.done()
  builder = LevelDataBuilder()
  builder.create(world)
  if output_tmpl:
    builder.save_bin(output_tmpl)
  if output_text:
    builder.save_text(output_level, output_text)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('-i', dest='init_count')
  parser.add_argument('-n', dest='nametable_tmpl')
  parser.add_argument('-a', dest='attribute_tmpl')
  parser.add_argument('-c', dest='collision_file')
  parser.add_argument('-s', dest='spawn_file')
  parser.add_argument('-o', dest='output_tmpl')
  parser.add_argument('-l', dest='output_level')
  parser.add_argument('-t', dest='output_text')
  args = parser.parse_args()
  process(args.init_count, args.nametable_tmpl, args.attribute_tmpl,
          args.collision_file, args.spawn_file,
          args.output_tmpl, args.output_level, args.output_text)


if __name__ == '__main__':
  run()
