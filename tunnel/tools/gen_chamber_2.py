# Generates scenes/chambers/chamber_2.tscn (placeholder greybox art).
# Chamber 2: first guard. Light the floor switch to raise the nearby timed door, then
# slip past the patrolling guard using a pillar and an alcove. Stay out of the
# one working ceiling lamp while he is looking.
L=[]
def a(s): L.append(s)
def pv(pts): return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x,y in pts) + ")"
def col(c): return "Color(%s, %s, %s, %s)" % (c+(1,) if len(c)==3 else c)
def rect(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

CEIL=-440
POOL_X=2079
FLOOR=[(-700,0),(1680,0),(1720,31),(2438,31),(2478,0),(3700,0),(3700,420),(-700,420)]
SWITCH_X=900
PILLAR_HIDE_X=1220
GUARD_L,GUARD_R,GUARD_START=1380,2500,2350
LAMP_X=1800
ALCOVE_X=2150
COLLISION_FLOOR=FLOOR[:3]+[(2055,31),(ALCOVE_X-55,0),(ALCOVE_X+55,0),(2245,31)]+FLOOR[3:]
CRATES_X=1600
LEVER_X=1120
NOISE_X=2450
DOOR_X=1040
EXIT_X=3020
RIGHT_WALL=3140

a('[gd_scene format=3]\n')
ext=[("Script","res://scripts/follow_camera.gd","s_cam"),("Script","res://scripts/hint_zone.gd","s_hint"),
     ("Script","res://scripts/passage_vent.gd","s_vent"),("Script","res://scripts/acid_pool.gd","s_acid"),
     ("Script","res://scripts/checkpoint_zone.gd","s_check"),
     ("Script","res://scripts/exit_zone.gd","s_exit"),
     ("Script","res://scripts/hide_zone.gd","s_hide"),("Script","res://scripts/lit_zone.gd","s_lit"),
     ("Script","res://scripts/enemy_guard.gd","s_guard"),("Script","res://scripts/floor_switch.gd","s_switch"),
     ("Script","res://scripts/tubeworm_cluster.gd","s_worm"),("Script","res://scripts/locked_door.gd","s_door"),("Script","res://scripts/noise_lever.gd","s_lever"),
     ("PackedScene","res://player.tscn","p_player"),("PackedScene","res://scenes/hud.tscn","p_hud"),
     ("Texture2D","res://art/light_radial.tres","t_light")]
for t,p,i in ext: a(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
a('')
shapes={"wall":(80,1400),"ceil":(4600,400),"hint_switch":(420,300),"checkpoint":(80,180),"hint_hide":(300,300),"hint_guard":(260,300),
        "exit":(80,300),"hide_pillar":(110,300),"hide_alcove":(100,300),"hide_crates":(110,300),"hint_lever":(160,300),"lit":(250,320)}
for k,(w,h) in shapes.items():
    a(f'[sub_resource type="RectangleShape2D" id="R_{k}"]\nsize = Vector2({w}, {h})\n')

a('[node name="Chamber2" type="Node2D"]\n')
a('[node name="GlobalDarkness" type="CanvasModulate" parent="."]\ncolor = Color(0.20, 0.19, 0.20, 1)\n')

# ---- backdrop
a('[node name="Backdrop" type="Node2D" parent="."]\nz_index = -10\n')
a(f'[node name="BackWall" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.33,0.32,0.30))}\npolygon = {pv(rect(-700,-1000,3700,20))}\n')
# Alcove: a deep recess in the back wall.
a(f'[node name="Alcove" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.12,0.115,0.11))}\npolygon = {pv(rect(ALCOVE_X-55,-230,ALCOVE_X+55,20))}\n')
a(f'[node name="AlcoveArch" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.22,0.21,0.2))}\npolygon = {pv(rect(ALCOVE_X-70,-250,ALCOVE_X+70,-230))}\n')
a(f'[node name="AlcoveLedge" type="Polygon2D" parent="Backdrop"]\nz_index = 12\ncolor = {col((0.18,0.15,0.12))}\npolygon = {pv([(ALCOVE_X-61,-2),(ALCOVE_X+61,-2),(ALCOVE_X+54,9),(ALCOVE_X-54,9)])}\n')
a(f'[node name="Lip" type="Line2D" parent="Backdrop/AlcoveLedge"]\npoints = {pv([(ALCOVE_X-60,-1),(ALCOVE_X+60,-1)])}\nwidth = 3.0\ndefault_color = {col((0.34,0.31,0.27))}\n')
for i,x in enumerate([-100,500,PILLAR_HIDE_X,2700]):
    a(f'[node name="Pillar{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.23,0.22,0.21))}\npolygon = {pv(rect(x-65,CEIL,x+65,20))}\n')
    a(f'[node name="PillarFace{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.28,0.27,0.26))}\npolygon = {pv(rect(x-65,CEIL,x-35,20))}\n')
a(f'[node name="SteelBeam" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.6,0.32,0.1))}\npolygon = {pv(rect(-700,-392,3700,-370))}\n')
a(f'[node name="SteelBeamShade" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.38,0.2,0.07))}\npolygon = {pv(rect(-700,-370,3700,-364))}\n')
# Ceiling fixtures: most are dead; a dim one at the start and switch, the one
# working lamp over the patrol, and one at the far door.
live={200:(0.45,1.0),SWITCH_X:(0.35,0.9),LAMP_X:(1.25,1.0),EXIT_X-80:(0.4,0.9)}
for i,x in enumerate([200,SWITCH_X,1350,LAMP_X,2250,2650,EXIT_X-80]):
    on = x in live
    a(f'[node name="Strip{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((1,0.86,0.36) if on else (0.2,0.19,0.18))}\npolygon = {pv(rect(x-35,-356,x+35,-350))}\n')
    if on:
        e,s=live[x]
        a(f'[node name="StripLight{i}" type="PointLight2D" parent="Backdrop"]\nposition = Vector2({x}, -330)\ncolor = Color(1, 0.74, 0.34, 1)\nenergy = {e}\ntexture = ExtResource("t_light")\ntexture_scale = {s}\n')
# The working lamp throws a cone of light to the floor.
a(f'[node name="LampPool" type="PointLight2D" parent="Backdrop"]\nposition = Vector2({LAMP_X}, -60)\ncolor = Color(1, 0.8, 0.45, 1)\nenergy = 1.1\ntexture = ExtResource("t_light")\ntexture_scale = 0.9\n')
a(f'[node name="LampShaft" type="Polygon2D" parent="Backdrop"]\nz_index = 1\ncolor = Color(1, 0.85, 0.5, 0.07)\npolygon = {pv([(LAMP_X-30,-350),(LAMP_X+30,-350),(LAMP_X+125,0),(LAMP_X-125,0)])}\n')
a('[node name="WarmHaze" type="PointLight2D" parent="Backdrop"]\nposition = Vector2(1600, -200)\ncolor = Color(1, 0.6, 0.3, 1)\nenergy = 0.12\ntexture = ExtResource("t_light")\ntexture_scale = 7.0\n')
a(f'[node name="Crates" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.26,0.2,0.14))}\npolygon = {pv(rect(CRATES_X-60,-140,CRATES_X+60,0))}\n')
a(f'[node name="CrateTop" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.31,0.24,0.17))}\npolygon = {pv(rect(CRATES_X-40,-215,CRATES_X+35,-140))}\n')
a(f'[node name="CeilingSlab" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.11,0.105,0.1))}\npolygon = {pv(rect(-700,-1000,3700,CEIL))}\n')

# ---- solid environment
a('[node name="EnvironmentWalls" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
a(f'[node name="FloorCollider" type="CollisionPolygon2D" parent="EnvironmentWalls"]\npolygon = {pv(COLLISION_FLOOR)}\n')
a(f'[node name="FloorBand" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.065,0.06,0.065))}\npolygon = {pv(FLOOR)}\n')
a(f'[node name="FloorLip" type="Line2D" parent="EnvironmentWalls"]\nz_index = 2\npoints = {pv(FLOOR[:-2])}\nwidth = 4.0\ndefault_color = Color(0.4, 0.39, 0.37, 1)\n')
a('[node name="LeftWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(-300, -300)\nshape = SubResource("R_wall")\n')
a(f'[node name="RightWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2({RIGHT_WALL}, -300)\nshape = SubResource("R_wall")\n')
a(f'[node name="Ceiling" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(1500, {CEIL-200})\nshape = SubResource("R_ceil")\n')

# ---- puzzle and enemy
a('[node name="PuzzlesAndHazards" type="Node2D" parent="."]\n')
a(f'[node name="FloorSwitch" type="Area2D" parent="PuzzlesAndHazards"]\nz_index = 3\nposition = Vector2({SWITCH_X}, 0)\nscript = ExtResource("s_switch")\ntarget_path = NodePath("../Door")\n')
a(f'[node name="Door" type="Node2D" parent="PuzzlesAndHazards"]\nz_index = 2\nposition = Vector2({DOOR_X}, 0)\nscript = ExtResource("s_door")\n')
a(f'[node name="NoiseLever" type="Area2D" parent="PuzzlesAndHazards"]\nposition = Vector2({LEVER_X}, 0)\nscript = ExtResource("s_lever")\nnoise_x = {NOISE_X}.0\n')
a(f'[node name="Guard" type="CharacterBody2D" parent="PuzzlesAndHazards"]\nz_index = 1\nposition = Vector2({GUARD_START}, 0)\nscript = ExtResource("s_guard")\npatrol_left = {GUARD_L}.0\npatrol_right = {GUARD_R}.0\nchase_margin_left = 1600.0\nchase_margin_right = 560.0\nstart_facing = -1\nfollow_floor = true\nfirst_sight_line = "Shit! Ministry’s here!\\nGotta hide! Lights out!"\n')

a(f'''[node name="ShallowAcidGlow" type="PointLight2D" parent="PuzzlesAndHazards"]
position = Vector2(2340, -6)
color = Color(0.55, 0.95, 0.2, 1)
energy = 0.5
texture = ExtResource("t_light")
texture_scale = 1.25

[node name="AcidSurfaceGlow" type="PointLight2D" parent="PuzzlesAndHazards"]
position = Vector2(2015, 8)
scale = Vector2(1, 0.23)
color = Color(0.55, 0.95, 0.2, 1)
energy = 0.26
texture = ExtResource("t_light")
texture_scale = 3.0

[node name="ShallowAcidPool" type="Area2D" parent="PuzzlesAndHazards" node_paths=PackedStringArray("glow", "guard")]
z_index = 3
position = Vector2({POOL_X}, 7)
script = ExtResource("s_acid")
half_width = 390.0
bottom_half_width = 359.0
depth = 24.0
has_dense_bed = false
entry_stalk_x = 261.0
entry_stalk_reach = 30.0
single_stalks = PackedFloat32Array(-224, -99, 146)
dry_ledge_x = {ALCOVE_X - POOL_X}.0
entry_warn_time = 1.25
glow = NodePath("../ShallowAcidGlow")
guard = NodePath("../Guard")
''')

a('''[node name="ExitSwitch" type="Area2D" parent="PuzzlesAndHazards"]
z_index = 3
position = Vector2(2700, 0)
script = ExtResource("s_switch")
target_path = NodePath("../ExitDoor")

[node name="ExitDoor" type="Node2D" parent="PuzzlesAndHazards"]
z_index = 2
position = Vector2(2850, 0)
script = ExtResource("s_door")
blocks_sight = true

[node name="ExitApproachWorms" type="Area2D" parent="PuzzlesAndHazards"]
z_index = 3
position = Vector2(2540, 0)
script = ExtResource("s_worm")
width = 90.0
max_height = 170.0
stalk_count = 7
random_seed = 21

[node name="CeilingWorms" type="Area2D" parent="PuzzlesAndHazards"]
z_index = 1
position = Vector2(2380, -440)
script = ExtResource("s_worm")
width = 110.0
max_height = 110.0
stalk_count = 8
from_ceiling = true
blocks_path = false
kill_if_caught = false
random_seed = 22

[node name="ExitWorms" type="Area2D" parent="PuzzlesAndHazards"]
z_index = 3
position = Vector2(2930, 0)
script = ExtResource("s_worm")
width = 70.0
max_height = 130.0
stalk_count = 6
random_seed = 23
''')

# ---- zones
a('[node name="EntryVent" type="Node2D" parent="PuzzlesAndHazards"]\nposition = Vector2(650, -65)\nscript = ExtResource("s_vent")\ntip_radius = 48.0\nreadable_grate = true\n')
a('[node name="PassageVent" type="Node2D" parent="PuzzlesAndHazards"]\nposition = Vector2(1450, -65)\nscript = ExtResource("s_vent")\ntip_radius = 48.0\n')
def zone(name, script, x, shape, extra=""):
    a(f'[node name="{name}" type="Area2D" parent="Zones"]\nposition = Vector2({x}, -150)\nscript = ExtResource("{script}")\n{extra}')
    a(f'[node name="Shape" type="CollisionShape2D" parent="Zones/{name}"]\nshape = SubResource("R_{shape}")\n')
a('[node name="Zones" type="Node2D" parent="."]\n')
a('[node name="Checkpoint" type="Area2D" parent="Zones"]\nposition = Vector2(835, -90)\nscript = ExtResource("s_check")\n')
a('[node name="Shape" type="CollisionShape2D" parent="Zones/Checkpoint"]\nshape = SubResource("R_checkpoint")\n')
zone("HintSwitch","s_hint",SWITCH_X,"hint_switch",'text = "SPACE   shine the lamp on the plate"\n')
zone("HintHide","s_hint",PILLAR_HIDE_X,"hint_hide",'text = "W / ↑   hide behind the pillar"\n')
zone("HintGuard","s_hint",1040,"hint_guard","text = \"Blue: he stops, then charges past you, so hide. Yellow: get out or he catches you. Don't touch him\"\n")
zone("HidePillar","s_hide",PILLAR_HIDE_X,"hide_pillar")
zone("HideAlcove","s_hide",ALCOVE_X,"hide_alcove")
zone("HideCrates","s_hide",CRATES_X,"hide_crates")
zone("HintLever","s_hint",LEVER_X,"hint_lever","text = \"E   bang the pipe. He'll go to the noise\"\n")
zone("LitPool","s_lit",LAMP_X,"lit")
zone("Exit","s_exit",EXIT_X,"exit",'next_scene = "res://scenes/chambers/chamber_3.tscn"\n')

# ---- player, camera, HUD
a('[node name="Player" parent="." instance=ExtResource("p_player")]\nz_index = 1\nposition = Vector2(0, 0)\n')
a(f'[node name="MainCamera" type="Camera2D" parent="."]\nposition = Vector2(0, -130)\nlimit_left = -340\nlimit_top = -640\nlimit_right = {RIGHT_WALL+40}\nlimit_bottom = 240\nposition_smoothing_enabled = true\nposition_smoothing_speed = 4.0\nscript = ExtResource("s_cam")\ntarget_path = NodePath("../Player")\n')
a('[node name="HUD" parent="." instance=ExtResource("p_hud")]\n')
open("scenes/chambers/chamber_2.tscn","w").write("\n".join(L))
