# Generates scenes/chambers/chamber_3.tscn (placeholder greybox art).
# Chamber 3: the scale shift. A long bridge over a chasm with five massive
# pillars. A searchlight on a far tower sweeps the bridge back and forth;
# run pillar to pillar and hug one (W / Up) as the light passes.
L=[]
def a(s): L.append(s)
def pv(pts): return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x,y in pts) + ")"
def col(c): return "Color(%s, %s, %s, %s)" % (c+(1,) if len(c)==3 else c)
def rect(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

DOORWAY_X=60
PILLARS=[800,1550,2300,3050,3800]
PILLAR_W=220
CHECKPOINTS=[1550,3050]
EXIT_X=4300
RIGHT_WALL=4420
LAMP=(2100,-520)
SWEEP_L,SWEEP_R=0,4250

a('[gd_scene format=3]\n')
ext=[("Script","res://scripts/follow_camera.gd","s_cam"),("Script","res://scripts/hint_zone.gd","s_hint"),
     ("Script","res://scripts/passage_vent.gd","s_vent"),
     ("Script","res://scripts/checkpoint_zone.gd","s_check"),("Script","res://scripts/exit_zone.gd","s_exit"),
     ("Script","res://scripts/hide_zone.gd","s_hide"),("Script","res://scripts/spotlight_sweep.gd","s_spot"),
     ("PackedScene","res://player.tscn","p_player"),("PackedScene","res://scenes/hud.tscn","p_hud"),
     ("Texture2D","res://art/light_radial.tres","t_light"),
     ("Script","res://scripts/enemy_guard.gd","s_guard"),
     ("Script","res://scripts/noise_lever.gd","s_lever")]
for t,p,i in ext: a(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
a('')
shapes={"wall":(80,1800),"ceil":(6000,400),"hint_start":(500,300),"hint_sprint":(300,300),
        "check":(60,300),"exit":(80,300),"hide_pillar":(160,300),"hide_door":(120,300)}
for k,(w,h) in shapes.items():
    a(f'[sub_resource type="RectangleShape2D" id="R_{k}"]\nsize = Vector2({w}, {h})\n')

a('[node name="Chamber3" type="Node2D"]\n')
a('[node name="GlobalDarkness" type="CanvasModulate" parent="."]\ncolor = Color(0.17, 0.175, 0.2, 1)\n')

# ---- backdrop: far cavern wall, the searchlight tower, the chasm below
a('[node name="Backdrop" type="Node2D" parent="."]\nz_index = -10\n')
a(f'[node name="FarWall" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.2,0.21,0.23))}\npolygon = {pv(rect(-800,-1400,5200,900))}\n')
# distant rock ribs for depth
for i,x in enumerate(range(-400,5200,520)):
    a(f'[node name="Rib{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.16,0.165,0.18))}\npolygon = {pv([(x,-1400),(x+140,-1400),(x+90,900),(x+20,900)])}\n')
lx,ly=LAMP
a(f'[node name="Tower" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.13,0.13,0.14))}\npolygon = {pv([(lx-40,ly+10),(lx+40,ly+10),(lx+110,900),(lx-110,900)])}\n')
a(f'[node name="TowerStrut" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.18,0.18,0.19))}\npolygon = {pv(rect(lx-70,ly+120,lx+70,ly+135))}\n')
a(f'[node name="Chasm" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.04,0.04,0.05))}\npolygon = {pv(rect(-800,120,5200,900))}\n')
a('[node name="ChasmGlow" type="PointLight2D" parent="Backdrop"]\nposition = Vector2(2100, 500)\ncolor = Color(1, 0.45, 0.2, 1)\nenergy = 0.25\ntexture = ExtResource("t_light")\ntexture_scale = 9.0\n')

# faint cold fill so the pillars read at scale
for i,x in enumerate(range(400,4400,700)):
    a(f'[node name="Fill{i}" type="PointLight2D" parent="Backdrop"]\nposition = Vector2({x}, -350)\ncolor = Color(0.55, 0.65, 0.85, 1)\nenergy = 0.35\ntexture = ExtResource("t_light")\ntexture_scale = 3.5\n')
# ---- the searchlight (beam z -2: in front of the backdrop, behind the pillars)
a(f'[node name="Searchlight" type="Node2D" parent="."]\nscript = ExtResource("s_spot")\nsource = Vector2({lx}, {ly})\nsweep_left = {SWEEP_L}.0\nsweep_right = {SWEEP_R}.0\nstart_x = 1700.0\nstart_dir = -1\nshadow_spans = {pv([(x-PILLAR_W//2, x+PILLAR_W//2) for x in PILLARS])}\n')

# ---- pillars (in front of the beam, behind the player)
a('[node name="Pillars" type="Node2D" parent="."]\nz_index = -1\nlight_mask = 2\n')
for i,x in enumerate(PILLARS):
    h=PILLAR_W//2
    a(f'[node name="Pillar{i}" type="Polygon2D" parent="Pillars"]\nlight_mask = 2\ncolor = {col((0.24,0.235,0.23))}\npolygon = {pv(rect(x-h,-1400,x+h,30))}\n')
    a(f'[node name="PillarLit{i}" type="Polygon2D" parent="Pillars"]\nlight_mask = 2\ncolor = {col((0.3,0.29,0.28))}\npolygon = {pv(rect(x-h,-1400,x-h+40,30))}\n')
    a(f'[node name="PillarBase{i}" type="Polygon2D" parent="Pillars"]\nlight_mask = 2\ncolor = {col((0.19,0.185,0.18))}\npolygon = {pv(rect(x-h-24,-60,x+h+24,30))}\n')
    a(f'[node name="PillarBand{i}" type="Polygon2D" parent="Pillars"]\nlight_mask = 2\ncolor = {col((0.55,0.3,0.1))}\npolygon = {pv(rect(x-h,-420,x+h,-404))}\n')
# entry doorway and exit arch
a(f'[node name="Doorway" type="Polygon2D" parent="Pillars"]\ncolor = {col((0.09,0.09,0.1))}\npolygon = {pv(rect(DOORWAY_X-70,-240,DOORWAY_X+70,0))}\n')
a(f'[node name="EntryWall" type="Polygon2D" parent="Pillars"]\ncolor = {col((0.22,0.215,0.21))}\npolygon = {pv(rect(-500,-1400,DOORWAY_X-70,30))}\n')
a(f'[node name="ExitArch" type="Polygon2D" parent="Pillars"]\ncolor = {col((0.09,0.09,0.1))}\npolygon = {pv(rect(EXIT_X-60,-240,EXIT_X+60,0))}\n')
a(f'[node name="ExitWall" type="Polygon2D" parent="Pillars"]\ncolor = {col((0.22,0.215,0.21))}\npolygon = {pv(rect(EXIT_X+60,-1400,5200,30))}\n')
a('[node name="ExitLight" type="PointLight2D" parent="Pillars"]\nposition = Vector2(%d, -150)\ncolor = Color(1, 0.7, 0.35, 1)\nenergy = 0.5\ntexture = ExtResource("t_light")\ntexture_scale = 0.8\n' % EXIT_X)

# ---- solid environment: the bridge deck
a('[node name="EnvironmentWalls" type="StaticBody2D" parent="."]\nmetadata/footstep_surface = "metal"\ncollision_mask = 0\n')
DECK=[(-500,0),(5200,0),(5200,120),(-500,120)]
a(f'[node name="FloorCollider" type="CollisionPolygon2D" parent="EnvironmentWalls"]\npolygon = {pv(DECK)}\n')
a(f'[node name="Deck" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.07,0.065,0.07))}\npolygon = {pv([(-500,0),(5200,0),(5200,40),(-500,40)])}\n')
a(f'[node name="DeckUnder" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.05,0.045,0.05))}\npolygon = {pv([(-500,40),(5200,40),(5200,70),(-500,70)])}\n')
for i,x in enumerate(range(-400,5200,240)):
    a(f'[node name="Truss{i}" type="Line2D" parent="EnvironmentWalls"]\nz_index = 2\npoints = {pv([(x,70),(x+120,130),(x+240,70)])}\nwidth = 6.0\ndefault_color = Color(0.06, 0.055, 0.06, 1)\n')
a(f'[node name="DeckLip" type="Line2D" parent="EnvironmentWalls"]\nz_index = 2\npoints = {pv([(-500,0),(5200,0)])}\nwidth = 4.0\ndefault_color = Color(0.4, 0.39, 0.37, 1)\n')
# railing behind the player
a(f'[node name="Rail" type="Line2D" parent="EnvironmentWalls"]\nz_index = -1\npoints = {pv([(-500,-70),(5200,-70)])}\nwidth = 5.0\ndefault_color = Color(0.3, 0.28, 0.26, 1)\n')
for i,x in enumerate(range(-400,5200,160)):
    a(f'[node name="Post{i}" type="Line2D" parent="EnvironmentWalls"]\nz_index = -1\npoints = {pv([(x,-70),(x,0)])}\nwidth = 4.0\ndefault_color = Color(0.26, 0.24, 0.22, 1)\n')
a('[node name="LeftWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(-300, -500)\nshape = SubResource("R_wall")\n')
a(f'[node name="RightWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2({RIGHT_WALL}, -500)\nshape = SubResource("R_wall")\n')
a('[node name="Ceiling" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(2200, -1600)\nshape = SubResource("R_ceil")\n')

# A backward lure: hide at pillar two while the guard investigates toward
# pillar one, then slip forward while still watching the tower's sweep.
a('[node name="BridgeGuard" type="CharacterBody2D" parent="."]\nz_index = 1\nposition = Vector2(2300, 0)\nscript = ExtResource("s_guard")\npatrol_left = 950.0\npatrol_right = 2600.0\nwalk_speed = 85.0\nstart_facing = 1\nchase_margin_left = 150.0\nchase_margin_right = 200.0\n')
a('[node name="NoiseLever" type="Area2D" parent="."]\nposition = Vector2(1550, 0)\nscript = ExtResource("s_lever")\nnoise_x = 950.0\npipe_y = -280.0\npanel_offset_y = -65.0\npanel_readable = true\n')

# The second patrol covers the last two pillars and the approach to the exit.
a('[node name="BridgeGuard2" type="CharacterBody2D" parent="."]\nz_index = 1\nposition = Vector2(3650, 0)\nscript = ExtResource("s_guard")\npatrol_left = 2800.0\npatrol_right = 4100.0\nwalk_speed = 85.0\nstart_facing = -1\nchase_margin_left = 200.0\nchase_margin_right = 150.0\n')

a('[node name="NoiseLeverEnd" type="Area2D" parent="."]\nposition = Vector2(3800, 0)\nscript = ExtResource("s_lever")\nnoise_x = 2800.0\npipe_y = -250.0\npanel_offset_y = -65.0\npanel_readable = true\n')

# ---- zones
for name,x in [("ApproachVent",1550),("MiddleVent",2300),("DepartureVent",3050)]:
    a(f'[node name="{name}" type="Node2D" parent="."]\nposition = Vector2({x}, -65)\nscript = ExtResource("s_vent")\ntip_radius = 48.0\nreadable_grate = true\n')
def zone(name, script, x, shape, extra=""):
    a(f'[node name="{name}" type="Area2D" parent="Zones"]\nposition = Vector2({x}, -150)\nscript = ExtResource("{script}")\n{extra}')
    a(f'[node name="Shape" type="CollisionShape2D" parent="Zones/{name}"]\nshape = SubResource("R_{shape}")\n')
a('[node name="Zones" type="Node2D" parent="."]\n')
zone("HintStart","s_hint",250,"hint_start","text = \"The light sweeps the bridge. W / ↑ hug a pillar as it passes\"\n")
zone("HintSprint","s_hint",1150,"hint_sprint","text = \"SHIFT   hurry to the next pillar\"\n")
zone("HideDoorway","s_hide",DOORWAY_X,"hide_door")
for i,x in enumerate(PILLARS):
    zone(f"HidePillar{i}","s_hide",x,"hide_pillar")
zone("Exit","s_exit",EXIT_X,"exit","next_scene = \"res://scenes/chambers/chamber_4.tscn\"\n")

# ---- player, camera (zoomed out for scale), HUD
a('[node name="Player" parent="." instance=ExtResource("p_player")]\nz_index = 1\nposition = Vector2(0, 0)\n')
a(f'[node name="MainCamera" type="Camera2D" parent="."]\nposition = Vector2(0, -130)\nzoom = Vector2(0.8, 0.8)\nlimit_left = -340\nlimit_top = -900\nlimit_right = {RIGHT_WALL+40}\nlimit_bottom = 320\nposition_smoothing_enabled = true\nposition_smoothing_speed = 4.0\nscript = ExtResource("s_cam")\ntarget_path = NodePath("../Player")\nvertical_offset = -200.0\n')
a('[node name="HUD" parent="." instance=ExtResource("p_hud")]\n')
open("scenes/chambers/chamber_3.tscn","w", encoding="utf-8").write("\n".join(L))
