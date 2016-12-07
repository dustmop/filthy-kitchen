import argparse
from makechr import chr_data
from makechr.gen import valiant_pb2 as valiant
from PIL import Image
import sys


def save_output(filename, data):
  fp = open(filename, 'wb')
  fp.write(bytearray(data))
  fp.close()


def fill_template(template, num):
  return template.replace('%d', '%02d' % num)


def kind_to_role(kind):
  if kind == 'chr':
    return valiant.CHR
  elif kind == 'nametable':
    return valiant.NAMETABLE
  elif kind == 'attribute':
    return valiant.ATTRIBUTE
  elif kind == 'palette':
    return valiant.PALETTE
  else:
    raise RuntimeError('Unknown kind %s' % kind)


def get_bytes(obj, kind, expand=False):
  role = kind_to_role(kind)
  for comp in obj.data.components:
    if comp.role == role:
      index = comp.binary_index
  binary = obj.data.binaries[index]
  data = binary.bin
  if expand:
    if binary.pre_pad:
      data = bytearray([binary.null_value] * binary.pre_pad) + data
    if binary.padding:
      data = data + bytearray([binary.null_value] * binary.padding)
  return bytearray(data)


def build_xlat(left_chr_page, right_chr_page):
  # Build translator so we can update the new nametable.
  i = j = 0
  xlat = {}
  while i < left_chr_page.num_idx() and j < right_chr_page.num_idx():
    c = left_chr_page.k_smallest(i)
    d = right_chr_page.k_smallest(j)
    if c < d:
      # Chr tile that only exists in left.
      i += 1
    elif c == d:
      # Chr tile matches, assign the new index.
      xlat[right_chr_page.index(j)] = left_chr_page.index(i)
      i += 1
      j += 1
    else: # c > d
      # Chr tile that is new, only exists in right.
      j += 1
  n = left_chr_page.size()
  for k in xrange(right_chr_page.size()):
    if not k in xlat:
      xlat[k] = n
      n += 1
  return xlat, n


def combine_chr(left_chr_page, right_chr_page, xlat):
  n = left_chr_page.size()
  j = n
  for i in xrange(right_chr_page.size()):
    if not i in xlat:
      continue
    k = xlat[i]
    if k >= n:
      left_chr_page.add(right_chr_page.get(i))
      j += 1


def perform_merge(left_chr_page, right_chr_page, nametable):
  (xlat, n) = build_xlat(left_chr_page, right_chr_page)
  combine_chr(left_chr_page, right_chr_page, xlat)
  for i,t in enumerate(nametable):
    try:
      nametable[i] = xlat[t]
    except KeyError:
      nametable[i] = 0xff
  return nametable


def insert_pad(data, position, num):
  make = bytearray([0] * len(data))
  for n, b in enumerate(data):
    if b >= position:
      make[n] = b + num
    else:
      make[n] = b
  return make


def merge_objects(collect, digit_obj, out_chr_name, out_palette_name,
                  out_nt_tmpl, out_attr_tmpl):
  obj = collect[0]
  chr_bin = get_bytes(obj, 'chr')
  nametable = get_bytes(obj, 'nametable', expand=True)
  attribute = get_bytes(obj, 'attribute', expand=True)
  save_output(fill_template(out_nt_tmpl, 0), insert_pad(nametable, 0x30, 10))
  save_output(fill_template(out_attr_tmpl, 0), attribute)
  palette = get_bytes(obj, 'palette', expand=True)
  save_output(out_palette_name, palette)
  combined_chr_page = chr_data.SortableChrPage.from_binary(str(chr_bin))
  for i,obj in enumerate(collect):
    if i == 0:
      continue
    chr_bin = get_bytes(obj, 'chr')
    nametable = get_bytes(obj, 'nametable', expand=True)
    attribute = get_bytes(obj, 'attribute', expand=True)
    right_chr_page = chr_data.SortableChrPage.from_binary(str(chr_bin))
    perform_merge(combined_chr_page, right_chr_page, nametable)
    save_output(fill_template(out_nt_tmpl, i), insert_pad(nametable, 0x30, 10))
    save_output(fill_template(out_attr_tmpl, i), attribute)
  data = combined_chr_page.to_bytes()
  data = data[0:0x300] + get_bytes(digit_obj, 'chr')[:0xa0] + data[0x300:]
  data = data + bytearray([0] * (0x2000 - len(data)))
  save_output(out_chr_name, data)



def downgrade_to_deprecated_proto(obj):
  # Future version
  if not obj.HasField('body'):
    return
  body = obj.body
  # Deprecated version
  data = obj.data
  data_settings = data.settings
  data_settings.bg_color = body.settings.bg_color
  # Each packet
  for i,packet in enumerate(body.packets):
    binary = data.binaries.add()
    binary.CopyFrom(packet.binary)
    component = data.components.add()
    component.role = packet.role
    component.binary_index = i
    if packet.name:
      component.name = packet.name
    metadata = packet.metadata
    if metadata.HasField('chr_metadata'):
      data_settings.chr_metadata.add().CopyFrom(metadata.chr_metadata)
    if metadata.HasField('palette_metadata'):
      data_settings.palette_metadata.add().CopyFrom(metadata.palette_metadata)
  # Clean-up
  obj.ClearField('body')


def parse_object_file(filename):
  fp = open(filename, 'rb')
  content = fp.read()
  fp.close()
  if content[0:9] != '(VALIANT)':
    raise RuntimeError('Could not parse file: %s' % f)
  obj = valiant.ObjectFile()
  obj.ParseFromString(content)
  downgrade_to_deprecated_proto(obj)
  return obj


def process(input_files, digits_input_file, out_chr_name, out_palette_name,
            out_nt_tmpl, out_attr_tmpl):
  collect = []
  for f in input_files:
    obj = parse_object_file(f)
    collect.append(obj)
  digit_obj = parse_object_file(digits_input_file)
  merge_objects(collect, digit_obj, out_chr_name, out_palette_name,
                out_nt_tmpl, out_attr_tmpl)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('input', type=str, nargs='+')
  parser.add_argument('-c', dest='chr')
  parser.add_argument('-p', dest='palette')
  parser.add_argument('-n', dest='nametable')
  parser.add_argument('-a', dest='attribute')
  parser.add_argument('-d', dest='digits')
  args = parser.parse_args()
  process(args.input, args.digits, args.chr, args.palette,
          args.nametable, args.attribute)


if __name__ == '__main__':
  run()
