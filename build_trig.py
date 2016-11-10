import argparse
import fixed_point
import math
import sys


NUM_DIRS = 64
QUARTER = NUM_DIRS / 4
TAU = 6.283185307179586


def to_fixed(value):
  return fixed_point.FixedPoint.from_float(value)


def build_movement(fout):
  fout.write('.export trig_movement\n')
  fout.write('trig_movement:\n')
  speed = 1.1
  # Interleave directions by turning a quarter turn at each step.
  for i in range(QUARTER):
    vals = []
    direction = i
    for j in range(5):
      movement = math.cos(direction * TAU / NUM_DIRS) * speed
      delta = fixed_point.FixedPoint.from_float(movement)
      vals.append(delta.low)
      vals.append(delta.high)
      direction = (direction + QUARTER) % NUM_DIRS
    fout.write('.byte %s\n' % ','.join(['$%02x' % e for e in vals]))


def build_lookup(fout):
  fout.write('.export trig_lookup\n')
  fout.write('trig_lookup:\n')
  for i in range(4):
    vals = []
    index = i
    for j in range(QUARTER):
      vals.append(index*2)
      index += 5
    fout.write('.byte %s\n' % ','.join(['$%02x' % e for e in vals]))


def build_header(fout):
  fout.write('.import trig_movement\n')
  fout.write('.import trig_lookup\n')


def run():
  parser = argparse.ArgumentParser()
  parser.add_argument('-a', dest='asm')
  parser.add_argument('-f', dest='header')
  args = parser.parse_args()
  fout = open(args.asm, 'w')
  build_movement(fout)
  build_lookup(fout)
  fout.close()
  fout = open(args.header, 'w')
  build_header(fout)
  fout.close()


if __name__ == '__main__':
  run()
