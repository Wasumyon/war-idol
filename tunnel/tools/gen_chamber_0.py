# Generates scenes/chambers/chamber_0.tscn (placeholder greybox art).
# Room 0: the fall. A tall vent shaft (x -140..140) drops into a low, dark service tunnel
# that runs right to the exit (-> Chamber 1). Vent worms sit in the shaft walls.
L=[]
def a(s): L.append(s)
def pv(pts): return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x,y in pts) + ")"
def col(c): return "Color(%s, %s, %s, %s)" % (c+(1,) if len(c)==3 else c)
def rect(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

SW=140            # shaft half-width
TOP=-4300         # top of the shaft (the hole he jumped into)
SPAWN_Y=-4050
TUN_CEIL=-320     # service tunnel ceiling
RIGHT=1700
EXIT_X=1560

a('[gd_scene format=3]\n')
ext=[("Script","res://scripts/follow_camera.gd","s_cam"),("Script","res://scripts/tubeworm_cluster.gd","s_worm"),
     ("Script","res://scripts/exit_zone.gd","s_exit"),("Script","res://scripts/room0_fall.gd","s_room"),("Script","res://scripts/vent_lunger.gd","s_lunge"),
     ("PackedScene","res://player.tscn","p_player"),("PackedScene","res://scenes/hud.tscn","p_hud"),
     ("Texture2D","res://art/light_radial.tres","t_light")]
for t,p,i in ext: a(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
a('')
shapes={"exit":(80,300)}
for k,(w,h) in shapes.items():
    a(f'[sub_resource type="RectangleShape2D" id="R_{k}"]\nsize = Vector2({w}, {h})\n')

a('[sub_resource type="CanvasItemMaterial" id="Material_controls"]\nlight_mode = 1\n')
a('[node name="Chamber0" type="Node2D"]\nscript = ExtResource("s_room")\n')
a('[node name="GlobalDarkness" type="CanvasModulate" parent="."]\ncolor = Color(0.17, 0.17, 0.19, 1)\n')

# ---- backdrop
a('[node name="Backdrop" type="Node2D" parent="."]\nz_index = -10\n')
# shaft: riveted duct panels
a(f'[node name="ShaftBack" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.26,0.26,0.28))}\npolygon = {pv(rect(-SW,TOP-200,SW,20))}\n')
for i,y in enumerate(range(TOP,0,180)):
    a(f'[node name="Seam{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.17,0.17,0.19))}\npolygon = {pv(rect(-SW,y,SW,y+6))}\n')
    a(f'[node name="SeamHi{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.36,0.36,0.37))}\npolygon = {pv(rect(-SW,y+6,SW,y+8))}\n')
for j,x in enumerate([-SW+16,SW-16]):
    a(f'[node name="Rib{j}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.2,0.2,0.22))}\npolygon = {pv(rect(x-6,TOP,x+6,0))}\n')
# the hole far above: dim orange glow from the fire up there
a(f'[node name="HoleGlow" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.9,0.5,0.2))}\npolygon = {pv(rect(-SW+20,TOP-200,SW-20,TOP))}\n')
a(f'[node name="HoleLight" type="PointLight2D" parent="Backdrop"]\nposition = Vector2(0, {TOP})\ncolor = Color(1, 0.55, 0.25, 1)\nenergy = 1.2\ntexture = ExtResource("t_light")\ntexture_scale = 3.0\n')
for i,(y,e) in enumerate([(-3500,0.45),(-2600,0.3),(-1700,0.18),(-900,0.1)]):
    a(f'[node name="ShaftSpill{i}" type="PointLight2D" parent="Backdrop"]\nposition = Vector2(0, {y})\ncolor = Color(1, 0.6, 0.35, 1)\nenergy = {e}\ntexture = ExtResource("t_light")\ntexture_scale = 3.2\n')
# service tunnel: grimy concrete, a low pipe, rubble where the grate came down
a(f'[node name="TunnelBack" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.24,0.23,0.22))}\npolygon = {pv(rect(SW,TUN_CEIL,RIGHT+200,20))}\n')
a(f'[node name="Pipe" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.33,0.22,0.13))}\npolygon = {pv(rect(SW,TUN_CEIL+40,RIGHT+200,TUN_CEIL+62))}\n')
for i,x in enumerate(range(400,RIGHT,420)):
    a(f'[node name="PipeClamp{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.2,0.15,0.1))}\npolygon = {pv(rect(x-8,TUN_CEIL,x+8,TUN_CEIL+66))}\n')
a(f'[node name="Doorway" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.05,0.05,0.05))}\npolygon = {pv(rect(EXIT_X-70,-230,EXIT_X+70,20))}\n')
a(f'[node name="DoorFrame" type="Line2D" parent="Backdrop"]\npoints = {pv([(EXIT_X-74,20),(EXIT_X-74,-234),(EXIT_X+74,-234),(EXIT_X+74,20)])}\nwidth = 8.0\ndefault_color = Color(0.5, 0.3, 0.12, 1)\n')
a(f'[node name="BeyondGlow" type="PointLight2D" parent="Backdrop"]\nposition = Vector2({EXIT_X+40}, -120)\ncolor = Color(1, 0.7, 0.35, 1)\nenergy = 0.5\ntexture = ExtResource("t_light")\ntexture_scale = 1.2\n')
# fallen grate + rubble at the landing spot
a('[node name="Rubble" type="Node2D" parent="."]\nz_index = 2\n')
rocks=[(-110,14,0.2),(-70,10,0.16),(95,16,0.22),(130,11,0.18),(210,9,0.17),(60,8,0.2)]
for i,(x,r,c) in enumerate(rocks):
    a(f'[node name="Rock{i}" type="Polygon2D" parent="Rubble"]\ncolor = {col((c,c*0.97,c*0.93))}\npolygon = {pv([(x-r,0),(x-r*0.6,-r*0.9),(x+r*0.3,-r),(x+r,-r*0.3),(x+r*0.8,0)])}\n')
a(f'[node name="Grate" type="Polygon2D" parent="Rubble"]\ncolor = {col((0.3,0.3,0.32))}\npolygon = {pv([(-150,0),(-30,-34),(-24,-26),(-144,6)])}\n')

# ---- solid environment
a('[node name="EnvironmentWalls" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
solids={
 "LeftWall":rect(-SW-1400,TOP-600,-SW,400),
 "RightWall":rect(SW,TOP-600,RIGHT+1400,TUN_CEIL),
 "Floor":rect(-SW-1400,0,RIGHT+1400,1000),
 "EndWall":rect(RIGHT,TUN_CEIL-400,RIGHT+1400,400),
}
for name,poly in solids.items():
    a(f'[node name="{name}" type="CollisionPolygon2D" parent="EnvironmentWalls"]\npolygon = {pv(poly)}\n')
    a(f'[node name="{name}Fill" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 3\ncolor = {col((0.06,0.055,0.06))}\npolygon = {pv(poly)}\n')
a(f'[node name="FloorLip" type="Line2D" parent="EnvironmentWalls"]\nz_index = 3\npoints = {pv([(-SW,0),(RIGHT,0)])}\nwidth = 4.0\ndefault_color = Color(0.38, 0.37, 0.35, 1)\n')
for name,pts in {"LeftLip":[(-SW,TOP-600),(-SW,0)],"RightLip":[(SW,TOP-600),(SW,TUN_CEIL),(RIGHT,TUN_CEIL)]}.items():
    a(f'[node name="{name}" type="Line2D" parent="EnvironmentWalls"]\nz_index = 3\npoints = {pv(pts)}\nwidth = 4.0\ndefault_color = Color(0.3, 0.3, 0.31, 1)\n')

# ---- vent worms in the shaft walls (harmless here: foreshadowing for the Ch 5 vent)
a('[node name="VentWorms" type="Node2D" parent="."]\nz_index = 2\n')
ys=list(range(-3700,-600,330))
for i,y in enumerate(ys):
    left = i%2==0
    x = -SW if left else SW
    rot = 90 if left else -90
    a(f'[node name="Worms{i}" type="Area2D" parent="VentWorms" groups=["vent_worms"]]\nposition = Vector2({x}, {y})\nrotation = {rot*3.14159265/180:.6f}\nscript = ExtResource("s_worm")\nwidth = 150.0\nmax_height = {150 if i < len(ys)-2 else 175}.0\nstalk_count = 10\nkill_if_caught = false\nblocks_path = false\nrandom_seed = {11+i*7}\n')

# ---- back-wall lungers: burst out of a grate and lunge at the camera (between the side worms)
a('[node name="VentLungers" type="Node2D" parent="."]\nz_index = -5\n')
for i,(x,y,tip) in enumerate([(-30,-3050,28),(40,-2230,30),(-20,-1400,32),(25,-820,34)]):
    a(f'[node name="Lunger{i}" type="Node2D" parent="VentLungers"]\nposition = Vector2({x}, {y})\nscript = ExtResource("s_lunge")\ntip_radius = {tip}.0\nrandom_seed = {5+i*4}\n')

# ---- zones
a('[node name="Zones" type="Node2D" parent="."]\n')
a(f'[node name="Exit" type="Area2D" parent="Zones"]\nposition = Vector2({EXIT_X+30}, -150)\nscript = ExtResource("s_exit")\nnext_scene = "res://scenes/chambers/chamber_1.tscn"\n')
a('[node name="Shape" type="CollisionShape2D" parent="Zones/Exit"]\nshape = SubResource("R_exit")\n')

# ---- player, camera, HUD
a(f'[node name="Player" parent="." instance=ExtResource("p_player")]\nz_index = 1\nposition = Vector2(0, {SPAWN_Y})\ntorch_starts_on = false\n')
a(f'[node name="MainCamera" type="Camera2D" parent="."]\nposition = Vector2(0, {SPAWN_Y-60})\nlimit_left = -420\nlimit_top = {TOP-500}\nlimit_right = {RIGHT+60}\nlimit_bottom = 220\nposition_smoothing_enabled = true\nposition_smoothing_speed = 9.0\nscript = ExtResource("s_cam")\ntarget_path = NodePath("../Player")\nvertical_offset = -60.0\nlook_ahead = 60.0\n')
a('[node name="HUD" parent="." instance=ExtResource("p_hud")]\n')
a('''[node name="ControlsSign" type="Node2D" parent="."]
material = SubResource("Material_controls")
modulate = Color(0.82, 0.75, 0.62, 1)
z_index = 1

[node name="Rule" type="Line2D" parent="ControlsSign"]
use_parent_material = true
points = PackedVector2Array(170, -181, 647, -181)
width = 1.0
default_color = Color(0.55, 0.49, 0.38, 1)

[node name="Move" type="Label" parent="ControlsSign"]
offset_left = 170.0
offset_top = -175.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "A / D: Move"

[node name="Sprint" type="Label" parent="ControlsSign"]
offset_left = 170.0
offset_top = -145.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "Shift: Sprint"

[node name="Lantern" type="Label" parent="ControlsSign"]
offset_left = 170.0
offset_top = -115.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "Space: Toggle lantern"

[node name="Hide" type="Label" parent="ControlsSign"]
offset_left = 435.0
offset_top = -175.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "W: Hide in cover"

[node name="Interact" type="Label" parent="ControlsSign"]
offset_left = 435.0
offset_top = -145.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "E: Interact"

[node name="Restart" type="Label" parent="ControlsSign"]
offset_left = 435.0
offset_top = -115.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "R: Restart checkpoint"

[node name="Menu" type="Label" parent="ControlsSign"]
offset_left = 435.0
offset_top = -85.0
mouse_filter = 2
use_parent_material = true
theme_override_font_sizes/font_size = 20
text = "Esc: Menu"
''')
open("scenes/chambers/chamber_0.tscn","w").write("\n".join(L))
