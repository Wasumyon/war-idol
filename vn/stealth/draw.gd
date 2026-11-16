extends RefCounted
## Flat floor drawings for the visor overlay: rings, dashed outlines, discs.

static func flat_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = color
	return mat


static func mesh_instance(mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## A ring lying on the XZ plane. With dashes > 0 it is cut into that many dashes.
static func ring_mesh(radius: float, width: float, segments := 64, dashes := 0) -> ArrayMesh:
	var verts := PackedVector3Array()
	var inner := radius - width
	if dashes <= 0:
		for i in segments:
			_arc_quad(verts, inner, radius, TAU * i / segments, TAU * (i + 1) / segments)
	else:
		var step := TAU / dashes
		for d in dashes:
			for s in 3:
				_arc_quad(verts, inner, radius,
					step * (d + 0.55 * s / 3.0), step * (d + 0.55 * (s + 1) / 3.0))
	return _mesh_from(verts)


static func disc_mesh(radius: float, segments := 48) -> ArrayMesh:
	var verts := PackedVector3Array()
	for i in segments:
		verts.append(Vector3.ZERO)
		verts.append(_on_circle(radius, TAU * i / segments))
		verts.append(_on_circle(radius, TAU * (i + 1) / segments))
	return _mesh_from(verts)


static func _arc_quad(verts: PackedVector3Array, inner: float, outer: float, a0: float, a1: float) -> void:
	var i0 := _on_circle(inner, a0)
	var i1 := _on_circle(inner, a1)
	var o0 := _on_circle(outer, a0)
	var o1 := _on_circle(outer, a1)
	verts.append_array([i0, o0, o1, i0, o1, i1])


static func _on_circle(radius: float, angle: float) -> Vector3:
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


static func _mesh_from(verts: PackedVector3Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
