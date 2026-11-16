# Generates scenes/chambers/chamber_1.tscn (placeholder greybox art).
# Order: walk hint -> shallow acid pool -> lamp hint -> floor-worm wall -> checkpoint ->
# acid pool with ambush worms (light only buys time: light up and run) -> exit.
L=[]
def a(s): L.append(s)
def pv(pts): return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x,y in pts) + ")"
def col(c): return "Color(%s, %s, %s, %s)" % (c+(1,) if len(c)==3 else c)
def rect(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

CEIL=-440
WALL_X=1300          # middle cluster of the three-deep worm wall
WALL_STEP=210
SHALLOW_X=500
POOL_X=2260          # middle of the acid surface
POOL_SURF=10
ENTRY_EXTENSION=64
# The pool dip has 75 px walkable slopes and a flat bottom 60 px deep.
FLOOR=[(-700,0),(SHALLOW_X-165,0),(SHALLOW_X-125,31),(SHALLOW_X+125,31),(SHALLOW_X+165,0),
       (POOL_X-320-ENTRY_EXTENSION,0),(POOL_X-245-ENTRY_EXTENSION,60),(POOL_X+245,60),(POOL_X+320,0),(3700,0),(3700,420),(-700,420)]

a('[gd_scene format=3]\n')
ext=[("Script","res://scripts/chip_objective.gd","s_objective"),
     ("Script","res://scripts/follow_camera.gd","s_cam"),("Script","res://scripts/tubeworm_cluster.gd","s_worm"),
     ("Script","res://scripts/hint_zone.gd","s_hint"),("Script","res://scripts/checkpoint_zone.gd","s_check"),
     ("Script","res://scripts/exit_zone.gd","s_exit"),("Script","res://scripts/acid_pool.gd","s_acid"),("PackedScene","res://player.tscn","p_player"),
     ("PackedScene","res://scenes/hud.tscn","p_hud"),("Texture2D","res://art/light_radial.tres","t_light")]
for t,p,i in ext: a(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
a('')
shapes={"wall":(80,1400),"ceil":(4600,400),"hint_walk":(700,300),"hint_lamp":(330,300),"check":(60,300),"exit":(80,300)}
for k,(w,h) in shapes.items():
    a(f'[sub_resource type="RectangleShape2D" id="R_{k}"]\nsize = Vector2({w}, {h})\n')

a('[node name="Chamber1" type="Node2D"]\n')
a('[node name="GlobalDarkness" type="CanvasModulate" parent="."]\ncolor = Color(0.21, 0.20, 0.21, 1)\n')

# ---- backdrop
a('[node name="Backdrop" type="Node2D" parent="."]\nz_index = -10\n')
a(f'[node name="BackWall" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.34,0.33,0.31))}\npolygon = {pv(rect(-700,-1000,3700,20))}\n')
for i,x in enumerate(range(-100,3400,600)):
    a(f'[node name="Pillar{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.23,0.22,0.21))}\npolygon = {pv(rect(x-65,CEIL,x+65,20))}\n')
    a(f'[node name="PillarFace{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.28,0.27,0.26))}\npolygon = {pv(rect(x-65,CEIL,x-35,20))}\n')
a(f'[node name="SteelBeam" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.6,0.32,0.1))}\npolygon = {pv(rect(-700,-392,3700,-370))}\n')
a(f'[node name="SteelBeamShade" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.38,0.2,0.07))}\npolygon = {pv(rect(-700,-370,3700,-364))}\n')
for i,x in enumerate(range(200,3400,600)):
    if 1000 < x < 1600 or 2300 < x < 2700: continue  # keep the worm wall and the pool in darkness
    a(f'[node name="Strip{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((1,0.86,0.36))}\npolygon = {pv(rect(x-35,-356,x+35,-350))}\n')
    a(f'[node name="StripLight{i}" type="PointLight2D" parent="Backdrop"]\nposition = Vector2({x}, -330)\ncolor = Color(1, 0.74, 0.34, 1)\nenergy = 0.6\ntexture = ExtResource("t_light")\ntexture_scale = 1.1\n')
a('[node name="WarmHaze" type="PointLight2D" parent="Backdrop"]\nposition = Vector2(700, -200)\ncolor = Color(1, 0.6, 0.3, 1)\nenergy = 0.18\ntexture = ExtResource("t_light")\ntexture_scale = 7.0\n')
a(f'[node name="CeilingSlab" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.11,0.105,0.1))}\npolygon = {pv(rect(-700,-1000,3700,CEIL))}\n')

a('[node name="PuzzlesAndHazards" type="Node2D" parent="."]\n')
# ---- acid glow (the pool node itself sits with the hazards)
a(f'[node name="AcidGlow" type="PointLight2D" parent="PuzzlesAndHazards"]\nposition = Vector2({POOL_X}, -10)\ncolor = Color(0.55, 0.95, 0.2, 1)\nenergy = 0.5\ntexture = ExtResource("t_light")\ntexture_scale = 2.6\n')
a(f'[node name="ShallowAcidGlow" type="PointLight2D" parent="PuzzlesAndHazards"]\nposition = Vector2({SHALLOW_X}, -6)\ncolor = Color(0.55, 0.95, 0.2, 1)\nenergy = 0.5\ntexture = ExtResource("t_light")\ntexture_scale = 1.55\n')

# ---- solid environment
a('[node name="EnvironmentWalls" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
a(f'[node name="FloorCollider" type="CollisionPolygon2D" parent="EnvironmentWalls"]\npolygon = {pv(FLOOR)}\n')
a(f'[node name="FloorBand" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.065,0.06,0.065))}\npolygon = {pv(FLOOR)}\n')
a(f'[node name="FloorLip" type="Line2D" parent="EnvironmentWalls"]\nz_index = 2\npoints = {pv(FLOOR[:-2])}\nwidth = 4.0\ndefault_color = Color(0.4, 0.39, 0.37, 1)\n')
a('[node name="LeftWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(-300, -300)\nshape = SubResource("R_wall")\n')
a('[node name="RightWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(3060, -300)\nshape = SubResource("R_wall")\n')
a(f'[node name="Ceiling" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(1500, {CEIL-200})\nshape = SubResource("R_ceil")\n')

# ---- hazards / puzzle
# floor worms: the wall. Light parts them, dark closes them; they never attack.
for i,dx in enumerate((-WALL_STEP,0,WALL_STEP)):
    name = "TubewormWall" if i == 0 else f"TubewormWall{i+1}"
    a(f'[node name="{name}" type="Area2D" parent="PuzzlesAndHazards"]\nz_index = 1\nposition = Vector2({WALL_X+dx}, 6)\nscript = ExtResource("s_worm")\nwidth = 240.0\nmax_height = {440 - 20*i}.0\nstalk_count = 22\nkill_if_caught = false\nrandom_seed = {7+i*13}\nlight_reach = 170.0\nretract_time = 0.8\n')
# The shallow pool has only the pair near its far bank.
a(f'[node name="ShallowAcidPool" type="Area2D" parent="PuzzlesAndHazards" node_paths=PackedStringArray("glow")]\nz_index = 3\nposition = Vector2({SHALLOW_X}, 7)\nscript = ExtResource("s_acid")\nhalf_width = 156.0\nbottom_half_width = 125.0\ndepth = 24.0\nhas_dense_bed = false\nentry_stalk_x = 89.0\nentry_stalk_reach = 30.0\nentry_warn_time = 1.25\nglow = NodePath("../ShallowAcidGlow")\n')
a(f'[node name="AcidPool" type="Area2D" parent="PuzzlesAndHazards" node_paths=PackedStringArray("glow")]\nz_index = 3\nposition = Vector2({POOL_X}, {POOL_SURF})\nscript = ExtResource("s_acid")\nhalf_width = 307.0\nbottom_half_width = 245.0\nentry_extension = {ENTRY_EXTENSION}.0\ndepth = 50.0\ndanger_start = -30.0\nentry_stalk_x = -228.0\nentry_stalk_reach = 30.0\nlight_hold_time = 0.95\nwarn_time = 0.34\nglow = NodePath("../AcidGlow")\n')

# ---- zones
def zone(name, script, x, shape, extra=""):
    a(f'[node name="{name}" type="Area2D" parent="Zones"]\nposition = Vector2({x}, -150)\nscript = ExtResource("{script}")\n{extra}')
    a(f'[node name="Shape" type="CollisionShape2D" parent="Zones/{name}"]\nshape = SubResource("R_{shape}")\n')
a('[node name="Zones" type="Node2D" parent="."]\n')
zone("HintWalk","s_hint",250,"hint_walk",'text = "A / D  or  ← →   walk     SHIFT   hurry (short burst)"\n')
zone("HintLamp","s_hint",WALL_X-WALL_STEP-320,"hint_lamp",'text = "SPACE   lamp on / off"\nhide_when_torch_on = true\n')
zone("Checkpoint","s_check",POOL_X-460,"check")  # right before the pool
zone("Exit","s_exit",2920,"exit",'next_scene = "res://scenes/chambers/chamber_2.tscn"\n')

# ---- player, camera, HUD
a('[node name="Player" parent="." instance=ExtResource("p_player")]\nz_index = 1\nposition = Vector2(0, 0)\n')
a('[node name="ChipObjective" type="PanelContainer" parent="Player"]\nscript = ExtResource("s_objective")\n')
a('[node name="MainCamera" type="Camera2D" parent="."]\nposition = Vector2(0, -130)\nlimit_left = -340\nlimit_top = -640\nlimit_right = 3100\nlimit_bottom = 240\nposition_smoothing_enabled = true\nposition_smoothing_speed = 4.0\nscript = ExtResource("s_cam")\ntarget_path = NodePath("../Player")\n')
a('[node name="HUD" parent="." instance=ExtResource("p_hud")]\n')
open("scenes/chambers/chamber_1.tscn","w").write("\n".join(L))
