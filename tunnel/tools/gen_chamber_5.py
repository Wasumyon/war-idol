# Generates scenes/chambers/chamber_5.tscn (placeholder greybox art).
# Chamber 5: the resolution. A cold passage opens into a warm room with a
# furnace and a cot. Controls drop away; he walks to the furnace and sits.
# Then the ending CG and a closing card.
L=[]
def a(s): L.append(s)
def pv(pts): return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x,y in pts) + ")"
def col(c): return "Color(%s, %s, %s, %s)" % (c+(1,) if len(c)==3 else c)
def rect(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

CEIL=-420
ROOM_L=520           # where the passage opens into the room
TRIGGER_X=640
SIT_X=1250
FURNACE_X=1420
COT_X=900
VENT=(1080,-330)
RIGHT_WALL=1640

a('[gd_scene format=3]\n')
ext=[("Script","res://scripts/follow_camera.gd","s_cam"),("Script","res://scripts/ending_sequence.gd","s_end"),
     ("Script","res://scripts/flicker_light.gd","s_flick"),
     ("PackedScene","res://player.tscn","p_player"),("PackedScene","res://scenes/hud.tscn","p_hud"),
     ("Texture2D","res://art/light_radial.tres","t_light")]
for t,p,i in ext: a(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
a('')
shapes={"wall":(80,1400),"ceil":(3000,400),"trigger":(60,300)}
for k,(w,h) in shapes.items():
    a(f'[sub_resource type="RectangleShape2D" id="R_{k}"]\nsize = Vector2({w}, {h})\n')

a('[node name="Chamber5" type="Node2D"]\n')
a('[node name="GlobalDarkness" type="CanvasModulate" parent="."]\ncolor = Color(0.14, 0.12, 0.11, 1)\n')

# ---- backdrop
a('[node name="Backdrop" type="Node2D" parent="."]\nz_index = -10\n')
# cold passage, then the warm room's plastered wall
a(f'[node name="PassageWall" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.22,0.23,0.25))}\npolygon = {pv(rect(-700,-1000,ROOM_L,20))}\n')
a(f'[node name="RoomWall" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.36,0.3,0.25))}\npolygon = {pv(rect(ROOM_L,-1000,RIGHT_WALL+200,20))}\n')
a(f'[node name="Doorframe" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.18,0.16,0.14))}\npolygon = {pv(rect(ROOM_L-30,CEIL,ROOM_L+30,20))}\n')
a(f'[node name="Wainscot" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.27,0.21,0.16))}\npolygon = {pv(rect(ROOM_L+30,-110,RIGHT_WALL+200,20))}\n')
# cot
a(f'[node name="CotFrame" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.2,0.17,0.14))}\npolygon = {pv(rect(COT_X-150,-55,COT_X+150,-40))}\n')
a(f'[node name="CotBlanket" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.42,0.28,0.2))}\npolygon = {pv([(COT_X-150,-55),(COT_X+150,-55),(COT_X+140,-78),(COT_X-120,-80)])}\n')
a(f'[node name="CotPillow" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.62,0.56,0.48))}\npolygon = {pv(rect(COT_X-145,-95,COT_X-90,-76))}\n')
for i,x in enumerate([COT_X-140,COT_X+140]):
    a(f'[node name="CotLeg{i}" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.16,0.13,0.11))}\npolygon = {pv(rect(x-6,-40,x+6,0))}\n')
# furnace: iron body, chimney, glowing mouth
fx=FURNACE_X
a(f'[node name="Chimney" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.14,0.13,0.12))}\npolygon = {pv(rect(fx-28,CEIL,fx+28,-230))}\n')
a(f'[node name="FurnaceBody" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.17,0.15,0.14))}\npolygon = {pv([(fx-110,0),(fx+110,0),(fx+95,-230),(fx-95,-230)])}\n')
a(f'[node name="FurnaceRim" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.55,0.3,0.1))}\npolygon = {pv(rect(fx-100,-236,fx+100,-226))}\n')
a(f'[node name="FurnaceMouth" type="Polygon2D" parent="Backdrop"]\ncolor = {col((1.0,0.55,0.2))}\npolygon = {pv(rect(fx-55,-120,fx+55,-40))}\n')
a(f'[node name="Embers" type="Polygon2D" parent="Backdrop"]\ncolor = {col((1.0,0.8,0.4))}\npolygon = {pv([(fx-50,-40),(fx+50,-40),(fx+30,-62),(fx-35,-58)])}\n')
vx,vy=VENT
a(f'[node name="VentDuct" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.2,0.18,0.16))}\npolygon = {pv(rect(vx-60,CEIL,vx+60,vy-28))}\n')
a(f'[node name="VentHole" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.03,0.03,0.03))}\npolygon = {pv(rect(vx-55,vy-28,vx+55,vy+28))}\n')
a(f'[node name="CeilingSlab" type="Polygon2D" parent="Backdrop"]\ncolor = {col((0.1,0.09,0.085))}\npolygon = {pv(rect(-700,-1000,RIGHT_WALL+200,CEIL))}\n')

a(f'[node name="Vent" type="Node2D" parent="."]\nz_index = -1\nposition = Vector2({vx}, {vy})\n')
bars=[pv(rect(-58,-30,58,-24)),pv(rect(-58,24,58,30))]+[pv(rect(x-3,-30,x+3,30)) for x in range(-50,51,20)]
a(f'[node name="Grille" type="Node2D" parent="Vent"]\n')
for i,b in enumerate(bars):
    a(f'[node name="Bar{i}" type="Polygon2D" parent="Vent/Grille"]\ncolor = {col((0.42,0.38,0.33))}\npolygon = {b}\n')

# ---- lights: cold dim passage, warm furnace
a('[node name="PassageLight" type="PointLight2D" parent="."]\nposition = Vector2(100, -300)\ncolor = Color(0.6, 0.68, 0.85, 1)\nenergy = 0.35\ntexture = ExtResource("t_light")\ntexture_scale = 2.5\n')
a(f'[node name="FurnaceLight" type="PointLight2D" parent="."]\nposition = Vector2({fx}, -80)\ncolor = Color(1, 0.55, 0.25, 1)\nenergy = 1.4\ntexture = ExtResource("t_light")\ntexture_scale = 3.2\nscript = ExtResource("s_flick")\n')
a(f'[node name="RoomGlow" type="PointLight2D" parent="."]\nposition = Vector2({(ROOM_L+RIGHT_WALL)//2}, -250)\ncolor = Color(1, 0.62, 0.35, 1)\nenergy = 0.35\ntexture = ExtResource("t_light")\ntexture_scale = 5.0\nscript = ExtResource("s_flick")\nstrength = 0.08\n')
a(f'[node name="MouthGlow" type="Polygon2D" parent="."]\nz_index = 1\ncolor = Color(1, 0.6, 0.3, 0.12)\npolygon = {pv([(fx-55,-120),(fx+55,-120),(fx+160,0),(fx-200,0)])}\n')

# ---- floor
FLOOR=[(-700,0),(RIGHT_WALL+200,0),(RIGHT_WALL+200,420),(-700,420)]
a('[node name="EnvironmentWalls" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
a(f'[node name="FloorCollider" type="CollisionPolygon2D" parent="EnvironmentWalls"]\npolygon = {pv(FLOOR)}\n')
a(f'[node name="FloorBand" type="Polygon2D" parent="EnvironmentWalls"]\nz_index = 2\ncolor = {col((0.065,0.055,0.05))}\npolygon = {pv(FLOOR)}\n')
a(f'[node name="FloorLip" type="Line2D" parent="EnvironmentWalls"]\nz_index = 2\npoints = {pv(FLOOR[:2])}\nwidth = 4.0\ndefault_color = Color(0.4, 0.34, 0.28, 1)\n')
a('[node name="LeftWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(-300, -300)\nshape = SubResource("R_wall")\n')
a(f'[node name="RightWall" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2({RIGHT_WALL}, -300)\nshape = SubResource("R_wall")\n')
a(f'[node name="Ceiling" type="CollisionShape2D" parent="EnvironmentWalls"]\nposition = Vector2(700, {CEIL-200})\nshape = SubResource("R_ceil")\n')

# ---- the ending
a(f'[node name="Ending" type="Area2D" parent="."]\nposition = Vector2({TRIGGER_X}, -150)\nscript = ExtResource("s_end")\nsit_x = {SIT_X}.0\nfurnace_light_path = NodePath("../FurnaceLight")\nvent_path = NodePath("../Vent")\ncamera_path = NodePath("../MainCamera")\nchip_land_x = {VENT[0]}.0\n')
a('[node name="Shape" type="CollisionShape2D" parent="Ending"]\nshape = SubResource("R_trigger")\n')

# ---- player, camera, HUD
a('[node name="Player" parent="." instance=ExtResource("p_player")]\nz_index = 1\nposition = Vector2(0, 0)\n')
a(f'[node name="MainCamera" type="Camera2D" parent="."]\nposition = Vector2(0, -130)\nlimit_left = -340\nlimit_top = -640\nlimit_right = {RIGHT_WALL+40}\nlimit_bottom = 240\nposition_smoothing_enabled = true\nposition_smoothing_speed = 3.0\nscript = ExtResource("s_cam")\ntarget_path = NodePath("../Player")\n')
a('[node name="HUD" parent="." instance=ExtResource("p_hud")]\n')
open("scenes/chambers/chamber_5.tscn","w").write("\n".join(L))
