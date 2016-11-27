import argparse
from PIL import Image
import tempfile
import os
import subprocess
from makechr import chr_data

RED  = (0xff,0,0)
BLUE = (0,0,0xff)
PINK_BG = (0xfc,0xb8,0xfc)

HORZ_FLIP = 0x40
VERT_FLIP = 0x80
SPIN_FLIP = 0xc0

SIZE_ID_MULTIPLE = 3


class PictureInfo(object):
  def __init__(self, identifier, origin_y, origin_x,
               is_flush=False, merge_count=None):
    self.is_flush = is_flush
    self.merge_count = merge_count
    self.identifier = identifier
    self.upcase = identifier.upper() if identifier else None
    self.origin_y = origin_y
    self.origin_x = origin_x
    self.target_y = None
    self.target_x = None
    self.picture = None
    self.sprite_list = None

  def skip(self):
    return self.origin_x is None or self.origin_y is None

  def __str__(self):
    if self.origin_y is None and self.target_y is None and self.is_flush:
      return '<PictureInfo flush>'
    elif self.origin_y is None and self.target_y is None and self.identifier:
      return '<PictureInfo ident=%s>' % (self.identifier,)
    else:
      return '<PictureInfo origin[y=%s x=%s] target[y=%s x=%s]>' % (
        self.origin_y, self.origin_x, self.target_y, self.target_x)


class Rect(object):
  def __init__(self, top, right, bottom, left):
    self.top = top
    self.right = right
    self.bottom = bottom
    self.left = left

  def grow(self, size):
    return Rect(self.top - 1, self.right + 1, self.bottom + 1, self.left - 1)

  def overlap(self, other):
    return (self._overlap(self.left, self.right, other.left, other.right) and
            self._overlap(self.top, self.bottom, other.top, other.bottom))

  def _overlap(self, a_min, a_max, b_min, b_max):
    return a_min <= b_max and b_min <= a_max

  def merge(self, other):
    return Rect(min(self.top, other.top),
                max(self.right, other.right),
                max(self.bottom, other.bottom),
                min(self.left, other.left))

  def __repr__(self):
    return '<Rect top=%s right=%s bottom=%s left=%s>' % (
      self.top, self.right, self.bottom, self.left)


class VertTile(object):
  def __init__(self, upper, lower):
    self.upper = upper
    self.lower = lower

  def get_bytes(self):
    bytes = self.upper.low + self.upper.hi + self.lower.low + self.lower.hi
    return bytearray(bytes)

  def flip(self, direction):
    if direction == 'h':
      return VertTile(self.upper.flip('h'), self.lower.flip('h'))
    elif direction == 'v':
      return VertTile(self.lower.flip('v'), self.upper.flip('v'))
    elif direction == 'vh':
      return VertTile(self.lower.flip('vh'), self.upper.flip('vh'))
    raise RuntimeError('Unknown flip direction "%s"' % direction)


def parse_info(filename):
  info_collection = []
  fp = open(filename, 'r')
  content = fp.read()
  fp.close()
  for line in content.split('\n'):
    if not line:
      continue
    if line.endswith(':'):
      ident = line[:-1]
      info_collection.append(PictureInfo(ident, None, None))
      continue
    if line == '.flush':
      info_collection.append(PictureInfo(None, None, None, is_flush=True))
      continue
    if line.startswith('.merge'):
      param = int(line.split(' ')[1])
      info_collection.append(PictureInfo(None, None, None, merge_count=param))
      continue
    pieces = line.split('@')
    identifier = pieces[0].strip()
    pos_y, pos_x = [int(n) for n in pieces[1].split(',')]
    info_collection.append(PictureInfo(identifier, pos_y, pos_x))
  return info_collection

def read_spritelist(filename):
  fp = open(filename, 'rb')
  data = fp.read()
  fp.close()
  if data[-1] != '\xff':
    raise RuntimeError('Spritelist doesnt end with "ff" terminator')
  data = data[:-1]
  sprites = [[ord(data[i*4+0]), ord(data[i*4+1]),
              ord(data[i*4+2]), ord(data[i*4+3])]
             for i in xrange(len(data) / 4)]
  return sprites

def read_chr(filename):
  fp = open(filename, 'r')
  fp.read(0x1000)
  chr_page = chr_data.ChrPage.from_binary(fp.read(0x1000))
  fp.close()
  return chr_page

def chr_to_lookup_map(chr_page):
  lookup = {}
  for i in xrange(chr_page.size() / 2):
    upper = chr_page.get(i*2+0)
    lower = chr_page.get(i*2+1)
    tile = VertTile(upper, lower)
    # Spin
    key = str(tile.flip('vh').get_bytes())
    if not key in lookup:
      lookup[key] = (i, SPIN_FLIP)
    # Horz
    key = str(tile.flip('h').get_bytes())
    if not key in lookup:
      lookup[key] = (i, HORZ_FLIP)
    # Vert
    key = str(tile.flip('v').get_bytes())
    if not key in lookup:
      lookup[key] = (i, VERT_FLIP)
    # Normal
    key = str(tile.get_bytes())
    if not key in lookup:
      lookup[key] = (i, 0x00)
  return lookup

def process_origins(filename, outfile):
  found_origin = None
  found_terminal = None
  origins = []
  # Create temporary file without the origins.
  img = Image.open(filename).convert('RGB')
  pixels = img.load()
  for y in xrange(img.size[1]):
    for x in xrange(img.size[0]):
      if pixels[x,y] == BLUE:
        if found_origin is None:
          found_origin = (y+1,x+1)
        found_terminal = (y+1,x+1)
        pixels[x,y] = PINK_BG
      elif not found_origin is None:
        # Go down as well.
        y_inner = y
        while y_inner < img.size[1]:
          if pixels[x-1,y_inner + 1] == BLUE:
            y_inner += 1
            continue
          found_terminal = (y_inner+1,x+1-1)
          break
        origins.append((found_origin, found_terminal))
        found_origin = found_terminal = None
  img.save(outfile)
  return origins

def extract_sprites(filename, chr_map):
  tmpdir = tempfile.mkdtemp()
  tmpfile = os.path.join(tmpdir, 'pictures.png')
  tmpzone = os.path.join(tmpdir, 'free-zone.png')
  print tmpdir
  #
  origins = process_origins(filename, tmpfile)
  outpattern = os.path.join(tmpdir, '%s.dat')
  # Run makechr to create spritelist.
  cmd = ['makechr', '-s', '-b', '39=34', '-t', 'free-8x16', tmpfile, '-l',
         '-o', outpattern, '--allow-overflow', 's', '--free-zone-view', tmpzone]
  p = subprocess.Popen(' '.join(cmd), shell=True)
  p.communicate()
  # Extract data created by makechr.
  chr_filename = outpattern.replace('%s', 'chr')
  chr_extracted = read_chr(chr_filename)
  spritelist_filename = outpattern.replace('%s', 'spritelist')
  sprites_extracted = read_spritelist(spritelist_filename)
  # Build tile number translator.
  xlat = {}
  for c in xrange(chr_extracted.size() / 2):
    upper = chr_extracted.get(c*2)
    lower = chr_extracted.get(c*2+1)
    bytes = upper.low + upper.hi + lower.low + lower.hi
    try:
      xlat[c] = chr_map[str(bytearray(bytes))]
    except KeyError:
      print 'Failed at %d' % c*2
  # Exchange tile numbers.
  for k, spr in enumerate(sprites_extracted):
    spr[0] = spr[0] + 1
    orig_tile = spr[1] / 2
    result = xlat[orig_tile]
    spr[1] = result[0] * 2 + 1
    spr[2] = result[1] | spr[2]
  return sprites_extracted, origins

def combine_info_with_origins(info_collection, origins):
  for info in info_collection:
    if info.skip():
      continue
    for origin, target in origins:
      if (info.origin_y, info.origin_x) == origin:
        info.target_y = target[0]
        info.target_x = target[1]
        break
    else:
      raise RuntimeError('Could not find origin, target for %s' % info)

def sprite_to_rect(sprite):
  y, tile, attr, x = sprite
  return Rect(y, x + 8, y + 16, x)

def derive_pictures(sprites, info_collection):
  available = set(range(0, len(sprites)))
  for info in info_collection:
    if info.skip():
      continue
    rect = Rect(info.origin_y, info.target_x, info.target_y, info.origin_x)
    single_picture = []
    while True:
      search = rect.grow(1)
      for i in available:
        sprite_rect = sprite_to_rect(sprites[i])
        if search.overlap(sprite_rect):
          single_picture.append(sprites[i])
          available.remove(i)
          rect = rect.merge(sprite_rect)
          break
        i += 1
      else:
        break
    if not single_picture:
      raise RuntimeError('stop %s' % rect)
    single_picture.sort(key=lambda x: (x[2], x[3], x[0]))
    info.picture = single_picture
  if available:
    print 'unused', [sprites[k] for k in available]


def build_data(info_collection):
  built_sprite_data = []
  sprite_data = {}
  sprite_counter = 0
  sprite_distance = 0
  for info in info_collection:
    if info.skip():
      if info.is_flush:
        built_sprite_data.append(sprite_data)
        sprite_data = {}
        sprite_counter = 0
        sprite_distance = 0
      continue
    flip_bits = info.picture[0][2] & SPIN_FLIP
    palette = info.picture[0][2] & 0x03
    assert all([(e[2] & SPIN_FLIP) == flip_bits for e in info.picture])
    sprite_list = []
    x_reset = 0
    for k, (y_pos, tile, attr, x_pos) in enumerate(info.picture):
      if attr & 0x03 != palette:
        sprite_list.append(0xfe)
        palette += 1
      y_offset = y_pos - info.origin_y
      x_offset = x_pos - info.origin_x - k*8
      key = (y_offset % 0x100, x_offset % 0x100, tile)
      if not key in sprite_data:
        sprite_data[key] = sprite_counter
        sprite_counter += 1
      sprite_id = sprite_data[key]
      if sprite_id >= 0x40:
        raise RuntimeError('Sprite ID overflow %02x, data = %s, name = %s' % (
          sprite_id,
          (y_pos, tile, attr, x_pos),
          info.identifier))
      sprite_list.append(sprite_id | flip_bits)
    sprite_list.append(0xff)
    info.sprite_list = sprite_list
    info.distance = sprite_distance
    sprite_distance += len(info.sprite_list)
  return built_sprite_data


def apply_merges(info_collection):
  merge_count = None
  accum = []
  value = None
  for info in info_collection:
    if not info.merge_count is None:
      merge_count = info.merge_count
      accum = []
      continue
    if merge_count:
      if info.identifier:
        if merge_count > 1:
          info.identifier = None
          value = info.distance
        else:
          info.distance = value
      if info.sprite_list:
        accum += info.sprite_list
        merge_count -= 1
        if merge_count > 0:
          info.origin_x, info.origin_y, info.sprite_list = (None, None, None)
          if accum[-1] == 0xff:
            accum[-1] = 0xfd
        else:
          info.sprite_list, accum, merge_count = (accum, [], None)


def produce_output(info_collection, built_sprite_data,
                   out_filename, out_header):
  built_idx = 0
  fout = open(out_filename, 'w')
  fheader = open(out_header, 'w')
  for info in info_collection:
    if info.skip():
      if info.identifier:
        fheader.write('.import %s\n' % info.identifier)
        fout.write('.export %s\n' % info.identifier)
        fout.write('%s:\n\n' % info.identifier)
      if info.is_flush:
        sprite_data = built_sprite_data[built_idx]
        built_idx += 1
        items = sprite_data.items()
        items.sort(key=lambda x:x[1])
        keys = [k for k,v in items]
        for k in keys:
          fout.write('.byte $%02x,$%02x,$%02x\n' % k)
        fout.write('\n')
    if not info.sprite_list:
      continue
    fheader.write('PICTURE_ID_%s = %s\n' % (info.upcase, info.distance))
    fout.write('PICTURE_ID_%s = %s\n' % (info.upcase, info.distance))
    fout.write('%s:\n' % info.identifier)
    fout.write('.byte %s\n' % ','.join(['$%02x' % e for e in info.sprite_list]))
    fout.write('\n')
  fout.close()
  fheader.close()


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('-i', dest='info')
  parser.add_argument('-p', dest='picture')
  parser.add_argument('-c', dest='chrfile')
  parser.add_argument('-o', dest='output')
  parser.add_argument('-header', dest='header')
  args = parser.parse_args()
  target_map = chr_to_lookup_map(read_chr(args.chrfile))
  sprites, origins = extract_sprites(args.picture, target_map)
  info_collection = parse_info(args.info)
  combine_info_with_origins(info_collection, origins)
  derive_pictures(sprites, info_collection)
  built_sprite_data = build_data(info_collection)
  apply_merges(info_collection)
  produce_output(info_collection, built_sprite_data, args.output, args.header)

if __name__ == '__main__':
  run()
