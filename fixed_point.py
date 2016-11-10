BYTE_SIZE = 256


class FixedPoint(object):
  def __init__(self, low=0, high=0):
    self.low = low
    self.high = high

  def add(self, other):
    carry = 0
    self.low += other.low
    if self.low >= BYTE_SIZE:
      carry = self.low / BYTE_SIZE
      self.low = self.low % BYTE_SIZE
    elif self.low < 0:
      negated = -self.low
      raise RuntimeError('stop')
    self.high = (self.high + other.high + carry) % BYTE_SIZE

  def sub(self, other):
    self.add(other.negate())

  def negate(self):
    carry = 0
    make = FixedPoint()
    make.low = (BYTE_SIZE - self.low) % BYTE_SIZE
    carry = (self.low != 0)
    make.high = (BYTE_SIZE - self.high - carry) % BYTE_SIZE
    return make

  def copy(self):
    make = FixedPoint()
    make.low = self.low
    make.high = self.high
    return make

  @staticmethod
  def from_float(f):
    signum = 1
    if f < 0:
      signum = -1
      f = -f
    make = FixedPoint()
    make.low = int(f * BYTE_SIZE) % BYTE_SIZE
    make.high = int(f) % BYTE_SIZE
    if signum == 1:
      return make
    else:
      return make.negate()

  def show(self):
    return '(L=%d H=%d)' % (self.low, self.high)
