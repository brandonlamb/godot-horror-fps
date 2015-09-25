tool
extends MeshInstance

export(ImageTexture) var heightmap setget set_heightmap, get_heightmap
export(float, 0.1, 100, 0.1) var factor = 5 setget set_factor, get_factor
export(int, 1, 500) var resolution = 32 setget set_resolution, get_resolution
export(int, 1, 1000) var size = 50 setget set_size, get_size

var mesh_builder

func _init():
	update_heightmap()
	
func _update_mesh():
	heightmap = self.heightmap
	factor = self.factor
	resolution = self.resolution
	size = float(self.size)
	
	var origin = Vector3(-size/2, 0, -size/2)
	var res_size = size/resolution
	
	var image
	var w
	var h
	
	var get_height = false
	
	if heightmap:
		image = heightmap.get_data()
		
		if image.empty():
			get_height = false
			
		else:
			get_height = true
			
			w = image.get_width() - 1
			h = image.get_height() - 1
			
	var surf = SurfaceTool.new()
	
	surf.begin(VS.PRIMITIVE_TRIANGLES)
	surf.add_smooth_group(true)
	
	for i in range(resolution):
		for j in range(resolution):
			var vertex_height = [0,0,0,0]
			
			if get_height:
				vertex_height[0] = image.get_pixel(w * float(i)/resolution, h * float(j)/resolution).gray() * factor
				vertex_height[1] = image.get_pixel(w * float(i+1)/resolution, h * float(j)/resolution).gray() * factor
				vertex_height[2] = image.get_pixel(w * float(i+1)/resolution, h * float(j+1)/resolution).gray() * factor
				vertex_height[3] = image.get_pixel(w * float(i)/resolution, h * float(j+1)/resolution).gray() * factor
			
			surf.add_uv(Vector2(0 + i, 0 + j)/resolution)
			surf.add_vertex(Vector3(i * res_size, vertex_height[0], j * res_size) + origin)
			
			surf.add_uv(Vector2(1 + i, 0 + j)/resolution)
			surf.add_vertex(Vector3((i+1) * res_size, vertex_height[1], j * res_size) + origin)
			
			surf.add_uv(Vector2(1 + i, 1 + j)/resolution)
			surf.add_vertex(Vector3((i+1) * res_size, vertex_height[2], (j+1) * res_size) + origin)
			
			surf.add_uv(Vector2(0 + i, 0 + j)/resolution)
			surf.add_vertex(Vector3(i * res_size, vertex_height[0], j * res_size) + origin)
			
			surf.add_uv(Vector2(1 + i, 1 + j)/resolution)
			surf.add_vertex(Vector3((i+1) * res_size, vertex_height[2], (j+1) * res_size) + origin)
			
			surf.add_uv(Vector2(0 + i, 1 + j)/resolution)
			surf.add_vertex(Vector3(i * res_size, vertex_height[3], (j+1) * res_size) + origin)
			
	surf.generate_normals()
	surf.index()
	
	var mesh = surf.commit()
	surf.clear()
	
	return mesh
	
func update_heightmap():
	var new_mesh = _update_mesh()
	
	new_mesh.set_name('Heightmap')
	set_mesh(new_mesh)
	
	if get_child_count():
		if get_child(0).get_type() == 'StaticBody':
			var col = get_child(0)
			
			remove_child(col)
			
			create_trimesh_collision()
			col.get_child(0).remove_and_skip()
			
			get_child(0).replace_by(col)
			
	else:
		create_trimesh_collision()
		
#Setter functions
func set_heightmap(newvalue):
	heightmap = newvalue
	
	update_heightmap()
	
func set_factor(newvalue):
	factor = newvalue
	
	update_heightmap()
	
func set_resolution(newvalue):
	resolution = newvalue
	
	update_heightmap()
	
func set_size(newvalue):
	size = newvalue
	
	update_heightmap()
	
#Getter functions
func get_heightmap():
	return heightmap
	
func get_factor():
	return factor
	
func get_resolution():
	return resolution
	
func get_size():
	return size