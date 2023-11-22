# file to just create rectangular dfn meshes for marking elements.

#injection points

# These points are from line_plane_intersection.py and are based on
# the vector created by these two points from 16A from AllWells_LocalCoords_Lynn.xl
# 136.6283296	235.5411389	326.2471586
# 145.7914766	236.3152936	322.3182035
# We could also get points directly from AllWells_LocalCoords_Lynn instead of assuming a straight line.

# zone,x,y,z
# 1.0,4.080888831e+02,2.584756670e+02,2.098508678e+02
# 2.0,3.101174933e+02,2.501984880e+02,2.518588363e+02
# 3.0,2.020881906e+02,2.410715595e+02,2.981794157e+02

#zone 1:
p1inx = 4.080888831e+02
p1iny = 2.584756670e+02
p1inz = 2.098508678e+02

#zone 2:
p2inx = 3.101174933e+02
p2iny = 2.501984880e+02
p2inz = 2.518588363e+02

#zone 3:
p3inx = 208 # 2.020881906e+02 # shifted to create straight homogenized fracture
p3iny = 2.410715595e+02
p3inz = 2.981794157e+02

# z-translation of fracture center
#50 puts the injection and production wells 100m apart
offset = 50

[Mesh]
  [frac1]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 5
    ny = 10
    xmin = '-100'
    xmax = '100'
    ymin = '-140'
    ymax = '140'
  []
  [center_frac1]
    type = TransformGenerator
    input = frac1
    transform = TRANSLATE_CENTER_ORIGIN
  []
  [rotate_frac1]
    type = TransformGenerator
    input = center_frac1
    transform = ROTATE
    vector_value = '0 90 87'
  []
  [translate_frac1]
    type = TransformGenerator
    input = rotate_frac1
    transform = TRANSLATE
    vector_value = '${p1inx} ${p1iny} ${fparse p1inz+offset}'
  []

  [frac2]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 5
    ny = 10
    xmin = '-100'
    xmax = '100'
    ymin = '-140'
    ymax = '140'
  []
  [center_frac2]
    type = TransformGenerator
    input = frac2
    transform = TRANSLATE_CENTER_ORIGIN
  []
  [rotate_frac2]
    type = TransformGenerator
    input = center_frac2
    transform = ROTATE
    vector_value = '0 90 87'
  []
  [translate_frac2]
    type = TransformGenerator
    input = rotate_frac2
    transform = TRANSLATE
    vector_value = '${p2inx} ${p2iny} ${fparse p2inz+offset}'
  []

  [frac3]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 5
    ny = 10
    xmin = '-100'
    xmax = '100'
    ymin = '-140'
    ymax = '140'
  []
  [center_frac3]
    type = TransformGenerator
    input = frac3
    transform = TRANSLATE_CENTER_ORIGIN
  []
  [rotate_frac3]
    type = TransformGenerator
    input = center_frac3
    transform = ROTATE
    vector_value = '0 90 87'
  []
  [translate_frac3]
    type = TransformGenerator
    input = rotate_frac3
    transform = TRANSLATE
    vector_value = '${p3inx} ${p3iny} ${fparse p3inz+offset}'
  []

  [combine]
    type = CombinerGenerator
    inputs = 'translate_frac1 translate_frac2 translate_frac3'
  []

[]
