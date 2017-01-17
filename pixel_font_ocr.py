def lookup_char(rows):
  if rows == [[1, 1, 1], [1, 0, 1], [1, 0, 1], [1, 0, 1], [1, 1, 1]]:
    return '0'
  elif rows == [[0, 1, 0], [1, 1, 0], [0, 1, 0], [0, 1, 0], [1, 1, 1]]:
    return '1'
  elif rows == [[0, 1, 0], [1, 0, 1], [0, 0, 1], [0, 1, 0], [1, 1, 1]]:
    return '2'
  elif rows == [[1, 1, 1], [0, 0, 1], [0, 1, 1], [0, 0, 1], [1, 1, 1]]:
    return '3'
  elif rows == [[1, 0, 1], [1, 0, 1], [1, 1, 1], [0, 0, 1], [0, 0, 1]]:
    return '4'
  elif rows == [[1, 1, 1], [1, 0, 0], [1, 1, 1], [0, 0, 1], [1, 1, 1]]:
    return '5'
  elif rows == [[1, 1, 1], [1, 0, 0], [1, 1, 1], [1, 0, 1], [1, 1, 1]]:
    return '6'
  elif rows == [[1, 1, 1], [0, 0, 1], [0, 0, 1], [0, 0, 1], [0, 0, 1]]:
    return '7'
  else:
    print rows
    raise NotImplementedError()


def fetch_single_row(pixels, y, x, bg_color):
  data = []
  data.append(0 if pixels[x+0,y] == bg_color else 1)
  data.append(0 if pixels[x+1,y] == bg_color else 1)
  data.append(0 if pixels[x+2,y] == bg_color else 1)
  return data


def fetch_single_char(pixels, y, x, bg_color):
  rows = []
  rows.append(fetch_single_row(pixels, y+0, x, bg_color))
  rows.append(fetch_single_row(pixels, y+1, x, bg_color))
  rows.append(fetch_single_row(pixels, y+2, x, bg_color))
  rows.append(fetch_single_row(pixels, y+3, x, bg_color))
  rows.append(fetch_single_row(pixels, y+4, x, bg_color))
  return lookup_char(rows)


def read_hex(image):
  width, height = image.size
  pixels = image.load()
  bg_color = pixels[0,0]
  first_char = fetch_single_char(pixels, 1, 1, bg_color)
  second_char = fetch_single_char(pixels, 1, 5, bg_color)
  return int(first_char + second_char, 16)
