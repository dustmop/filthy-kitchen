import argparse
import os
import shutil
import subprocess
import tempfile


def run_command(cmd):
  print('    ' + cmd)
  p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
  out, err = p.communicate()
  if p.returncode != 0:
    raise RuntimeError(err)


def fill_template(template, param):
  if '%d' in template:
    return template.replace('%d', '%02d' % param)
  elif '%s' in template:
    return template.replace('%s', param)
  else:
    raise RuntimeError('Template needs %%d or %%s, found "%s"' % template)


def list_template(template):
  if not '%d' in template:
    raise RuntimeError('Template needs %%d, found "%s"' % template)
  i = 0
  while True:
    instance = template.replace('%d', '%02d' % i)
    if os.path.isfile(instance):
      yield instance
    else:
      raise StopIteration()
    i += 1


def copy_file(source, destination):
  shutil.copy2(source, destination)


def process(bg_image, meta_image, level_num, palette, include,
            alpha_file, digit_file, out_text, out_chr, out_extra):
  tmp_dir = tempfile.mkdtemp()
  # Split the background image into individual screens.
  split_screens = os.path.join(tmp_dir, 'screen%d.png')
  cmd = 'python split_level.py %s -o %s' % (bg_image, split_screens)
  run_command(cmd)
  # Compile the screens with makechr.
  objects = []
  for screen in list_template(split_screens):
    obj_file = screen.replace('.png', '.o')
    cmd = 'makechr %s -b 0f -p %s -o %s' % (screen, palette, obj_file)
    run_command(cmd)
    objects.append(obj_file)
  # Merge the results of makechr to get single chr, multiple nametables.
  chr_built = os.path.join(tmp_dir, 'chr.dat')
  nt_built = os.path.join(tmp_dir, 'nametable%d.dat')
  attr_built = os.path.join(tmp_dir, 'attribute%d.dat')
  cmd = 'python merge_chr_nt.py %s %s -A %s -D %s -c %s -n %s -a %s' % (
    include, ' '.join(objects), alpha_file, digit_file,
    chr_built, nt_built, attr_built)
  run_command(cmd)
  # First included file is the hud data.
  copy_file(fill_template(nt_built, 0), fill_template(out_extra, 'nametable'))
  copy_file(fill_template(attr_built, 0), fill_template(out_extra, 'attribute'))
  # Build collision data.
  collision_built = os.path.join(tmp_dir, 'collision.dat')
  spawn_built = os.path.join(tmp_dir, 'spawn.dat')
  cmd = 'python build_collision_spawn.py %s -c %s -s %s' % (
    meta_image, collision_built, spawn_built)
  run_command(cmd)
  # Build structs.
  cmd = 'python build_structs.py -n %s -i 1 -a %s -c %s -s %s -l %s -t %s' % (
    nt_built, attr_built, collision_built, spawn_built, level_num, out_text)
  run_command(cmd)
  # Copy chr.
  copy_file(chr_built, out_chr)


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('-b', dest='bg_image')
  parser.add_argument('-m', dest='meta_image')
  parser.add_argument('-l', dest='level_num')
  parser.add_argument('-p', dest='palette')
  parser.add_argument('-i', dest='include') # Multiple?
  parser.add_argument('-A', dest='alpha_file')
  parser.add_argument('-D', dest='digit_file')
  parser.add_argument('-o', dest='out_text')
  parser.add_argument('-c', dest='out_chr')
  parser.add_argument('-x', dest='out_extra')
  args = parser.parse_args()
  process(args.bg_image, args.meta_image, args.level_num,
          args.palette, args.include, args.alpha_file, args.digit_file,
          args.out_text, args.out_chr, args.out_extra)


if __name__ == '__main__':
  run()
