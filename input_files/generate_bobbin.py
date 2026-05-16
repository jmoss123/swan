import gmsh
import sys

gmsh.initialize()
gmsh.model.add("bobbin")

L  = 16.5   # outer half-size (mm)
t = 2       # thickness (mm)
r = 3.0     # outer fillet radius (mm)
ms = 1.0    # mesh size (mm)

# Derived inner dimensions (guarantees constant wall thickness)
Li = L - t          # inner half-size = 14.5mm
ri = r - t          # inner fillet radius = 1.0mm

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
outer_lines = [lo_bot, arc_br, lo_rgt, arc_tr, lo_top, arc_tl, lo_lft, arc_bl]
outer_loop  = gmsh.model.geo.addCurveLoop(outer_lines)

# INNER boundary: simple square (creates hollow centre)

fic_bl = gmsh.model.geo.addPoint(-Li+ri, -Li+ri, 0)
fic_br = gmsh.model.geo.addPoint( Li-ri, -Li+ri, 0)
fic_tr = gmsh.model.geo.addPoint( Li-ri,  Li-ri, 0)
fic_tl = gmsh.model.geo.addPoint(-Li+ri,  Li-ri, 0)

ia1 = gmsh.model.geo.addPoint(-Li+ri, -Li,    0, ms)
ia2 = gmsh.model.geo.addPoint(-Li,    -Li+ri, 0, ms)
ia3 = gmsh.model.geo.addPoint( Li-ri, -Li,    0, ms)
ia4 = gmsh.model.geo.addPoint( Li,    -Li+ri, 0, ms)
ia5 = gmsh.model.geo.addPoint( Li,     Li-ri, 0, ms)
ia6 = gmsh.model.geo.addPoint( Li-ri,  Li,    0, ms)
ia7 = gmsh.model.geo.addPoint(-Li+ri,  Li,    0, ms)
ia8 = gmsh.model.geo.addPoint(-Li,     Li-ri, 0, ms)

li_bot = gmsh.model.geo.addLine(ia1, ia3)
li_rgt = gmsh.model.geo.addLine(ia4, ia5)
li_top = gmsh.model.geo.addLine(ia6, ia7)
li_lft = gmsh.model.geo.addLine(ia8, ia2)

iarc_bl = gmsh.model.geo.addCircleArc(ia2, fic_bl, ia1)
iarc_br = gmsh.model.geo.addCircleArc(ia3, fic_br, ia4)
iarc_tr = gmsh.model.geo.addCircleArc(ia5, fic_tr, ia6)
iarc_tl = gmsh.model.geo.addCircleArc(ia7, fic_tl, ia8)

inner_lines = [li_bot, iarc_br, li_rgt, iarc_tr, li_top, iarc_tl, li_lft, iarc_bl]
inner_loop  = gmsh.model.geo.addCurveLoop(inner_lines)

gmsh.model.geo.synchronize()

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
gmsh.model.addPhysicalGroup(1, inner_lines, 2)
gmsh.model.setPhysicalName(1, 2, "bobbin_inner")

# MESH SETTINGS

gmsh.option.setNumber("Mesh.CharacteristicLengthMin", 0.8)
gmsh.option.setNumber("Mesh.CharacteristicLengthMax", 1.2)
gmsh.option.setNumber("Mesh.ElementOrder", 1)
gmsh.option.setNumber("Mesh.RecombineAll", 1)    # Prefer quads
gmsh.option.setNumber("Mesh.Algorithm", 8)       # Frontal-Delaunay for quads

gmsh.model.mesh.generate(2)
gmsh.write("bobbin_fillet.msh")
gmsh.write("bobbin_fillet.vtk") # for visualization in Paraview
gmsh.finalize()

print("Mesh written to bobbin_fillet.msh and bobbin_fillet.vtk")
