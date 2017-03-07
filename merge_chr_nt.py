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
  for packet in obj.body.packets:
    if packet.role == role:
      binary = packet.binary
      break
  else:
    return bytearray()
  data = binary.bin
  if expand:
    if binary.pre_pad:
      data = bytearray([binary.null_value] * binary.pre_pad) + data
    if binary.padding:
      data = data + bytearray([binary.null_value] * binary.padding)
  return bytearray(data)


def read_chr_file(filename):
  fp = open(filename, 'r')
  content = fp.read()
  fp.close()
  empty_tile = bytearray([0]*16)
  i = len(content)
  while True:
    if i - 16 <= 0:
      break
    if content[i-16:i] == empty_tile:
      i -= 16
    else:
      break
  return bytearray(content[0:i])


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


def insert_pad(data, padding):
  make = bytearray([0] * len(data))
  for n, b in enumerate(data):
    i = b
    for p, k in padding:
      if i >= p:
        i += k
    try:
      make[n] = i
    except:
      sys.stderr.write('Error setting %s <- %s\n' % (n, i))
  return make


def add_charset_padding(padding, charset):
  for ch in charset:
    padding.append([ord(ch), 1])
  return padding


def insert_chr_data_from_charset(data, alpha_obj, charset):
  alpha_chr = get_bytes(alpha_obj, 'chr')
  for ch in charset:
    n = ord(ch)
    k = n - 0x41
    data = data[:0x10 * n] + alpha_chr[k*0x10:k*0x10+0x10] + data[0x10 * n:]
  return data


def merge_objects(input_files, alpha_obj, digit_obj, punc_obj, charset,
                  out_chr_name, out_palette_name, out_nt_tmpl, out_attr_tmpl):
  padding = []
  if punc_obj:
    padding.append([0x20,  4])
  if digit_obj:
    padding.append([0x30, 10])
  if alpha_obj and not charset:
    padding.append([0x41, 26])
  if alpha_obj and charset:
    padding = add_charset_padding(padding, charset)
  filename = input_files[0]
  if filename.endswith('.o'):
    obj = parse_object_file(filename)
    chr_bin = get_bytes(obj, 'chr')
    nametable = get_bytes(obj, 'nametable', expand=True)
    attribute = get_bytes(obj, 'attribute', expand=True)
    save_output(fill_template(out_nt_tmpl, 0), insert_pad(nametable, padding))
    save_output(fill_template(out_attr_tmpl, 0), attribute)
    palette = get_bytes(obj, 'palette', expand=True)
    if out_palette_name:
      save_output(out_palette_name, palette)
  else:
    chr_bin = read_chr_file(filename)
  combined_chr_page = chr_data.SortableChrPage.from_binary(str(chr_bin))
  for i,filename in enumerate(input_files):
    if i == 0:
      continue
    obj = parse_object_file(filename)
    chr_bin = get_bytes(obj, 'chr')
    nametable = get_bytes(obj, 'nametable', expand=True)
    attribute = get_bytes(obj, 'attribute', expand=True)
    right_chr_page = chr_data.SortableChrPage.from_binary(str(chr_bin))
    perform_merge(combined_chr_page, right_chr_page, nametable)
    save_output(fill_template(out_nt_tmpl, i), insert_pad(nametable, padding))
    save_output(fill_template(out_attr_tmpl, i), attribute)
  data = combined_chr_page.to_bytes()
  if punc_obj:
    data = data[:0x200] + get_bytes(punc_obj, 'chr')[:0x40] + data[0x200:]
  if digit_obj:
    data = data[:0x300] + get_bytes(digit_obj, 'chr')[:0xa0] + data[0x300:]
  if alpha_obj and not charset:
    data = data[:0x410] + get_bytes(alpha_obj, 'chr')[:0x1a0] + data[0x410:]
  if alpha_obj and charset:
    data = insert_chr_data_from_charset(data, alpha_obj, charset)
  data = data + bytearray([0] * (0x2000 - len(data)))
  if out_chr_name:
    save_output(out_chr_name, data)


def parse_object_file(filename):
  if filename is None:
    return None
  fp = open(filename, 'rb')
  content = fp.read()
  fp.close()
  if content[0:9] != '(VALIANT)':
    raise RuntimeError('Could not parse file: %s' % f)
  obj = valiant.ObjectFile()
  obj.ParseFromString(content)
  return obj


def process(input_files, alpha_input_file, digits_input_file, punc_input_file,
            charset, out_chr_name, out_palette_name, out_nt_tmpl,
            out_attr_tmpl):
  alpha_obj = parse_object_file(alpha_input_file)
  digit_obj = parse_object_file(digits_input_file)
  punc_obj = parse_object_file(punc_input_file)
  merge_objects(input_files, alpha_obj, digit_obj, punc_obj, charset,
                out_chr_name, out_palette_name, out_nt_tmpl, out_attr_tmpl)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('input', type=str, nargs='+')
  parser.add_argument('-c', dest='chr')
  parser.add_argument('-p', dest='palette')
  parser.add_argument('-n', dest='nametable')
  parser.add_argument('-a', dest='attribute')
  parser.add_argument('-A', dest='alpha')
  parser.add_argument('-D', dest='digits')
  parser.add_argument('-C', dest='charset')
  parser.add_argument('-P', dest='punc')
  args = parser.parse_args()
  process(args.input, args.alpha, args.digits, args.punc, args.charset,
          args.chr, args.palette, args.nametable, args.attribute)


if __name__ == '__main__':
  run()
