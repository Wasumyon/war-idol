# Generates scenes/chambers/chamber_4.tscn (placeholder greybox art).
# Chamber 4: the climax. The floor is a carpet of tubeworms. A guard paces a
# catwalk overhead, his lantern throwing a pool of light on the floor ahead of
# him. The pool holds the worms down; its bright core is where he looks.
# No checkpoints: every death restarts the chamber (keeps the pace).
# Two guards: A over the first bed, B over the last. The short middle bed
# and the ledge past B's bulkhead are out of everyone's sight (breathers).
# Ride the dim fringe; lamp on only when his back is turned.
L=[]
def a(s): L.append(s)
def pv(pts): return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x,y in pts) + ")"
def col(c): return "Color(%s, %s, %s, %s)" % (c+(1,) if len(c)==3 else c)
def rect(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

CATWALK_Y=-460
# bed 1 (Guard A) | pillar 1 | short bed 2 (nobody watches) | pillar 2 | bed 3 (Guard B) | safe ledge
STRETCHES=[(420,1160),(1360,1610),(1810,2620)]
PILLARS=[1260,1710]          # full-height pillars, also the catwalk bulkheads
PILLAR_HW=70
END_BULKHEAD=2760            # end of Guard B's catwalk; the ledge past bed 3 is out of sight
WORM_W=140
WORM_STEP=110
GUARDS=[  # name, patrol, start x, facing, sight min, sight max, light min, light max
    ("GuardA",(350,1030),350,1,-100000,PILLARS[0]-10,-100000,PILLARS[0]-PILLAR_HW),
    ("GuardB",(1940,2290),2100,-1,PILLARS[1]+10,END_BULKHEAD,STRETCHES[2][0],STRETCHES[2][1]),
]
EXIT_X=3050
RIGHT_WALL=3190

a('[gd_scene format=3]\n')
ext=[("Script","res://scripts/follow_camera.gd","s_cam"),("Script","res://scripts/hint_zone.gd","s_hint"),
     ("Script","res://scripts/checkpoint_zone.gd","s_check"),("Script","res://scripts/exit_zone.gd","s_exit"),
     ("Script","res://scripts/hide_zone.gd","s_hide"),("Script","res://scripts/catwalk_guard.gd","s_guard"),
     ("Script","res://scripts/tubeworm_cluster.gd","s_worm"),
     ("PackedScene","res://player.tscn","p_player"),("PackedScene","res://scenes/hud.tscn","p_hud"),
     ("Texture2D","res://art/light_radial.tres","t_light")]
for t,p,i in ext: a(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
a('')
shapes={"wall":(80,1800),"ceil":(5000,400),"hint_start":(400,300),"hint_island":(180,300),
        "check":(60,300),"exit":(80,300),"hide_support":(160,300),"hide_door":(120,300)}
for k,(w,h) in shapes.items():
    a(f'[sub_resource type="RectangleShape2D" id="R_{k}"]\nsize = Vector2({w}, {h})\n')

a('[node name="Chamber4" type="Node2D"]\n')
a('[node name="GlobalDarkness" type="CanvasModulate" parent="."]\ncolor = Color(0.17, 0.16, 0.17, 1)\n')

# ---- backdrop
a('[node name="Backdrop" type="Node2D" parent="."]\nz_index = -10\n')
a(f'[node name="BackWall" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.25,0.24,0.24))}\npolygon = {pv(rect(-700,-1300,3700,40))}\n')
for i,x in enumerate(range(-200,3500,450)):
    a(f'[node name="Rib{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.19,0.185,0.185))}\npolygon = {pv([(x,-1300),(x+110,-1300),(x+80,40),(x+30,40)])}\n')
a(f'[node name="CeilingSlab" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.1,0.095,0.095))}\npolygon = {pv(rect(-700,-1300,3700,-860))}\n')
a('[node name="Haze" type="PointLight2D" parent="Backdrop"]\nposition = Vector2(1500, -300)\ncolor = Color(0.6, 0.55, 0.6, 1)\nenergy = 0.12\ntexture = ExtResource("t_light")\ntexture_scale = 8.0\n')

# ---- catwalks overhead (behind the player): A's runs to pillar 1, B's from pillar 2
# to the end bulkhead. No catwalk over the middle bed: nobody watches it.
a('[node name="Catwalk" type="Node2D" parent="."]\nz_index = -1\n')
cy=CATWALK_Y
DECKS=[(-500,PILLARS[0]-PILLAR_HW),(PILLARS[1]+PILLAR_HW,END_BULKHEAD)]
n=0
for d,(x0,x1) in enumerate(DECKS):
    a(f'[node name="Deck{d}" type="Polygon2D" parent="Catwalk"]\ncolor = {col((0.16,0.15,0.15))}\npolygon = {pv(rect(x0,cy,x1,cy+18))}\n')
    a(f'[node name="DeckEdge{d}" type="Line2D" parent="Catwalk"]\npoints = {pv([(x0,cy),(x1,cy)])}\nwidth = 3.0\ndefault_color = Color(0.45, 0.42, 0.4, 1)\n')
    a(f'[node name="Rail{d}" type="Line2D" parent="Catwalk"]\npoints = {pv([(x0,cy-80),(x1,cy-80)])}\nwidth = 4.0\ndefault_color = Color(0.32, 0.3, 0.28, 1)\n')
    for x in range(x0+20,x1,140):
        a(f'[node name="Post{n}" type="Line2D" parent="Catwalk"]\npoints = {pv([(x,cy-80),(x,cy)])}\nwidth = 3.0\ndefault_color = Color(0.28, 0.26, 0.25, 1)\n'); n+=1
    for x in range(x0,x1-140,280):
        a(f'[node name="Truss{n}" type="Line2D" parent="Catwalk"]\npoints = {pv([(x,cy+18),(x+140,cy+60),(x+280,cy+18)])}\nwidth = 5.0\ndefault_color = Color(0.13, 0.12, 0.12, 1)\n'); n+=1
    for x in range(x0+120,x1,520):
        a(f'[node name="Chain{n}" type="Line2D" parent="Catwalk"]\npoints = {pv([(x,-860),(x,cy)])}\nwidth = 3.0\ndefault_color = Color(0.2, 0.19, 0.18, 1)\n'); n+=1
# end bulkhead: a wall hanging from the ceiling where B's catwalk stops
a(f'[node name="EndBulkhead" type="Polygon2D" parent="Catwalk"]\ncolor = {col((0.15,0.145,0.14))}\npolygon = {pv(rect(END_BULKHEAD-30,-860,END_BULKHEAD+30,cy+60))}\n')

# ---- pillars: floor to ceiling, between the beds (hide spots, and they cut the catwalks)
a('[node name="Supports" type="Node2D" parent="."]\nz_index = -1\nlight_mask = 2\n')
for i,x in enumerate(PILLARS):
    h=PILLAR_HW
    a(f'[node name="Pillar{i}" type="Polygon2D" parent="Supports"]\nlight_mask = 2\ncolor = {col((0.21,0.2,0.19))}\npolygon = {pv(rect(x-h,-860,x+h,10))}\n')
    a(f'[node name="PillarFace{i}" type="Polygon2D" parent="Supports"]\nlight_mask = 2\ncolor = {col((0.27,0.26,0.25))}\npolygon = {pv(rect(x-h,-860,x-h+24,10))}\n')
    a(f'[node name="Plinth{i}" type="Polygon2D" parent="Supports"]\nlight_mask = 2\ncolor = {col((0.19,0.18,0.17))}\npolygon = {pv(rect(x-h-30,-34,x+h+30,10))}\n')
# entry and exit doorways
a(f'[node name="Doorway" type="Polygon2D" parent="Supports"]\ncolor = {col((0.08,0.08,0.09))}\npolygon = {pv(rect(-10,-240,130,0))}\n')
a(f'[node name="EntryWall" type="Polygon2D" parent="Supports"]\ncolor = {col((0.22,0.21,0.2))}\npolygon = {pv(rect(-500,-860,-10,30))}\n')
a(f'[node name="ExitArch" type="Polygon2D" parent="Supports"]\ncolor = {col((0.08,0.08,0.09))}\npolygon = {pv(rect(EXIT_X-60,-240,EXIT_X+60,0))}\n')
a(f'[node name="ExitWall" type="Polygon2D" parent="Supports"]\ncolor = {col((0.22,0.21,0.2))}\npolygon = {pv(rect(EXIT_X+60,-860,3700,30))}\n')
a('[node name="ExitLight" type="PointLight2D" parent="Supports"]\nposition = Vector2(%d, -150)\ncolor = Color(1, 0.7, 0.35, 1)\nenergy = 0.6\ntexture = ExtResource("t_light")\ntexture_scale = 0.8\n' % EXIT_X)

# ---- floor
a('[node name="EnvironmentWalls" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
a(f'[node name="FloorCollider" type="CollisionPolygon2D" parent="EnvironmentWalls"]\npolygon = {pv(rect(-500,0,3700,200))}\n')
a(f'[node name="FloorBand" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.065,0.06,0.065))}\npolygon = {pv(rect(-500,0,3700,200))}\n')
a(f'[node name="FloorLip" type="Line2D" parent="EnvironmentWalls"]\nz_index = 2\npoints = {pv([(-500,0),(3700,0)])}\nwidth = 4.0\ndefault_color = Color(0.4, 0.39, 0.37, 1)\n')
for i,(x0,x1) in enumerate(STRETCHES):
    # the worm beds: a dark wet trench edge, lit faintly red from below
    a(f'[node name="Bed{i}" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.12,0.04,0.05))}\npolygon = {pv(rect(x0,0,x1,10))}\n')
    a(f'[node name="BedGlow{i}" type="PointLight2D" parent="EnvironmentWalls"]\nposition = Vector2({(x0+x1)//2}, 30)\ncolor = Color(0.9, 0.25, 0.2, 1)\nenergy = 0.45\ntexture = ExtResource("t_light")\ntexture_scale = 3.2\n')
a('[node name="LeftWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(-300, -500)\nshape = SubResource("R_wall")\n')
a(f'[node name="RightWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2({RIGHT_WALL}, -500)\nshape = SubResource("R_wall")\n')
a('[node name="Ceiling" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(1500, -1060)\nshape = SubResource("R_ceil")\n')

# ---- the worm floor: touching grown worms kills; light (his pool, your lamp) holds them down
a('[node name="Tubeworms" type="Node2D" parent="."]\n')
n=0
for x0,x1 in STRETCHES:
    x=x0+WORM_W//2
    while x<=x1-WORM_W//2:
        a(f'[node name="Worms{n}" type="Area2D" parent="Tubeworms"]\nz_index = 1\nposition = Vector2({x}, 6)\nscript = ExtResource("s_worm")\nwidth = {WORM_W}.0\nmax_height = 230.0\nstalk_count = 9\ndeadly = true\nkill_if_caught = false\nblocks_path = false\nretract_time = 0.4\nregrow_delay = 0.5\nregrow_time = 1.0\nrandom_seed = {11+n*7}\n')
        n+=1; x+=WORM_STEP

# ---- the guards on the catwalks
for name,(pl,pr),gx,face,smin,smax,lmin,lmax in GUARDS:
    a(f'[node name="{name}" type="Node2D" parent="."]\nz_index = -1\nposition = Vector2({gx}, {CATWALK_Y})\nscript = ExtResource("s_guard")\npatrol_left = {pl}.0\npatrol_right = {pr}.0\nstart_facing = {face}\nfloor_y = 0.0\nsight_min_x = {smin}.0\nsight_max_x = {smax}.0\nlight_min_x = {lmin}.0\nlight_max_x = {lmax}.0\n')

# ---- zones
def zone(name, script, x, shape, extra=""):
    a(f'[node name="{name}" type="Area2D" parent="Zones"]\nposition = Vector2({x}, -150)\nscript = ExtResource("{script}")\n{extra}')
    a(f'[node name="Shape" type="CollisionShape2D" parent="Zones/{name}"]\nshape = SubResource("R_{shape}")\n')
a('[node name="Zones" type="Node2D" parent="."]\n')
zone("HintStart","s_hint",220,"hint_start","text = \"His light holds the worms down. Keep to its dim edge, out of the bright centre\"\n")
zone("HintGap","s_hint",PILLARS[0],"hint_island","text = \"Nobody watches the gap. Your lamp holds the worms down too\"\n")
zone("HintLamp","s_hint",PILLARS[1],"hint_island","text = \"W / ↑   hide.   Lamp on only while his back is turned\"\n")
zone("HideDoorway","s_hide",60,"hide_door")
for i,x in enumerate(PILLARS):
    zone(f"HidePillar{i}","s_hide",x,"hide_support")
zone("Exit","s_exit",EXIT_X,"exit","next_scene = \"res://scenes/chambers/chamber_5.tscn\"\n")

# ---- player, camera, HUD
a('[node name="Player" parent="." instance=ExtResource("p_player")]\nz_index = 1\nposition = Vector2(0, 0)\n')
a(f'[node name="MainCamera" type="Camera2D" parent="."]\nposition = Vector2(0, -130)\nzoom = Vector2(0.8, 0.8)\nlimit_left = -340\nlimit_top = -900\nlimit_right = {RIGHT_WALL+40}\nlimit_bottom = 260\nposition_smoothing_enabled = true\nposition_smoothing_speed = 4.0\nscript = ExtResource("s_cam")\ntarget_path = NodePath("../Player")\nvertical_offset = -260.0\n')
a('[node name="HUD" parent="." instance=ExtResource("p_hud")]\n')
open("scenes/chambers/chamber_4.tscn","w").write("\n".join(L))
print("worm clusters:", n)
