import gmsh
import sys

gmsh.initialize()
gmsh.model.add("bobbin")

L  = 16.5   # outer half-size (mm)
Li = 15.5   # inner half-size (L - 1mm wall)
r = 2.0     # fillet radius (mm)
ms = 1.0    # mesh size (mm)

# OUTER boundary: square with filleted corners

# Fillet arc centre points (inset by r from each outer corner)
fc_bl = gmsh.model.geo.addPoint(-L+r, -L+r, 0)   # bottom-left centre
fc_br = gmsh.model.geo.addPoint( L-r, -L+r, 0)   # bottom-right centre
fc_tr = gmsh.model.geo.addPoint( L-r,  L-r, 0)   # top-right centre
fc_tl = gmsh.model.geo.addPoint(-L+r,  L-r, 0)   # top-left centre

# Arc endpoint pairs
pa1 = gmsh.model.geo.addPoint(-L+r, -L,    0, ms)  # bottom-left arc start
pa2 = gmsh.model.geo.addPoint(-L,   -L+r,  0, ms)  # bottom-left arc end
pa3 = gmsh.model.geo.addPoint( L-r, -L,    0, ms)  # bottom-right arc start
pa4 = gmsh.model.geo.addPoint( L,   -L+r,  0, ms)  # bottom-right arc end
pa5 = gmsh.model.geo.addPoint( L,    L-r,  0, ms)  # top-right arc start
pa6 = gmsh.model.geo.addPoint( L-r,  L,    0, ms)  # top-right arc end
pa7 = gmsh.model.geo.addPoint(-L+r,  L,    0, ms)  # top-left arc start
pa8 = gmsh.model.geo.addPoint(-L,    L-r,  0, ms)  # top-left arc end

# Flat edges between arcs
lo_bot = gmsh.model.geo.addLine(pa1, pa3)   # bottom flat
lo_rgt = gmsh.model.geo.addLine(pa4, pa5)   # right flat
lo_top = gmsh.model.geo.addLine(pa6, pa7)   # top flat
lo_lft = gmsh.model.geo.addLine(pa8, pa2)   # left flat

# Corner fillet arcs (start, centre, end)
arc_bl = gmsh.model.geo.addCircleArc(pa2,  fc_bl, pa1)
arc_br = gmsh.model.geo.addCircleArc(pa3,  fc_br, pa4)
arc_tr = gmsh.model.geo.addCircleArc(pa5,  fc_tr, pa6)
arc_tl = gmsh.model.geo.addCircleArc(pa7,  fc_tl, pa8)

# Outer curve loop (counter-clockwise)
outer_loop = gmsh.model.geo.addCurveLoop([
    lo_bot,   # bottom flat (left to right)
    arc_br,   # bottom-right fillet
    lo_rgt,   # right flat (bottom to top)
    arc_tr,   # top-right fillet
    lo_top,   # top flat (right to left)
    arc_tl,   # top-left fillet
    lo_lft,   # left flat (top to bottom)
    arc_bl    # bottom-left fillet
])

# INNER boundary: simple square (creates hollow centre)

pi1 = gmsh.model.geo.addPoint(-Li, -Li, 0, ms)
pi2 = gmsh.model.geo.addPoint( Li, -Li, 0, ms)
pi3 = gmsh.model.geo.addPoint( Li,  Li, 0, ms)
pi4 = gmsh.model.geo.addPoint(-Li,  Li, 0, ms)

li1 = gmsh.model.geo.addLine(pi1, pi2)   # bottom
li2 = gmsh.model.geo.addLine(pi2, pi3)   # right
li3 = gmsh.model.geo.addLine(pi3, pi4)   # top
li4 = gmsh.model.geo.addLine(pi4, pi1)   # left

# Inner curve loop (clockwise to create hole in surface)
inner_loop = gmsh.model.geo.addCurveLoop([li1, li2, li3, li4])

# Surface: Region between outer fillet boundary and inner hole

surface = gmsh.model.geo.addPlaneSurface([outer_loop, inner_loop])

gmsh.model.geo.synchronize()

# Physical groups: These names become boundary names in MOOSE

# Bobbin wall (2D elements)
gmsh.model.addPhysicalGroup(2, [surface], 1)
gmsh.model.setPhysicalName(2, 1, "bobbin_skin")

# Outer filleted surface - contact primary surface in MOOSE
gmsh.model.addPhysicalGroup(1, [lo_bot, arc_br, lo_rgt, arc_tr,
                                 lo_top, arc_tl, lo_lft, arc_bl], 1)
gmsh.model.setPhysicalName(1, 1, "bobbin_outer")

# Inner surface - rotation BC applied here
gmsh.model.addPhysicalGroup(1, [li1, li2, li3, li4], 2)
gmsh.model.setPhysicalName(1, 2, "bobbin_inner")

# MESH SETTINGS

gmsh.option.setNumber("Mesh.CharacteristicLengthMin", 0.8)
gmsh.option.setNumber("Mesh.CharacteristicLengthMax", 1.2)
gmsh.option.setNumber("Mesh.ElementOrder", 1)
gmsh.option.setNumber("Mesh.RecombineAll", 1)    # Prefer quads
gmsh.option.setNumber("Mesh.Algorithm", 8)       # Frontal-Delaunay for quads

gmsh.model.mesh.generate(2)
gmsh.write("bobbin_fillet.msh")
gmsh.finalize()

print("Mesh written to bobbin_fillet.msh")
