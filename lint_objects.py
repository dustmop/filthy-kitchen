import re
import sys

def has_scalar(text):
  return re.search(r'\bplayer_', text)

def has_field(text):
  return re.search(r'\bobject_', text) or re.search(r'\bswatter_', text)

def has_x_index(text):
  return re.search(r',x\b', text) or re.search(r',y\b', text)

def should_ignore(text):
  words = ['.import', '.export', '.include', '.byte', ' = ',
           'object_list_head', 'object_list_tail', 'objects_only_draw',
           '!no_lint',
           'swatter_animation_sequence',
           'swatter_picture_data', 'swatter_sprite_data']
  for w in words:
    if w in text:
      return True
  return False

def is_mov(text):
  return re.search(r'\bmov\b', text)

_g_error_text = ''

def add_error(num_line, line, kind):
  if kind == 'scalar_x':
    tmpl = '%d: Scalar with an X index\n'
  else:
    tmpl = '%d: Field without X index\n'
  msg = tmpl % num_line
  global _g_error_text
  _g_error_text += msg

def show_error():
  global _g_error_text
  if not _g_error_text:
    return False
  print(_g_error_text)
  return True

def process(filename):
  fp = open(filename, 'r')
  content = fp.read()
  fp.close()
  num_line = 0
  for line in content.split('\n'):
    num_line += 1
    if is_mov(line):
      # TODO: Fix this.
      continue
    elif has_scalar(line) and has_x_index(line):
      if not should_ignore(line):
        add_error(num_line, line, 'scalar_x')
        continue
    elif has_field(line) and not has_x_index(line):
      if not should_ignore(line):
        add_error(num_line, line, 'field_alone')
  if show_error():
    sys.exit(1)

if __name__ == '__main__':
  process(sys.argv[1])

