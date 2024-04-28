extends SubViewportContainer

@onready var viewport = $SubViewport
@onready var texture_rect = $SubViewport/TextureRect
@onready var threshold_rect = %ThresholdRect

enum PIXEL_STATUS {
	EMPTY,
	PREVIOUSLY_SEARCHED,
	FULL,
	PART_OF_LARGEST_ISLAND
}

#The heart and soul
func get_flood_data() -> Dictionary:
	show()
	
	
	await get_tree().create_timer(0.2).timeout
	
	var texture: Texture = viewport.get_texture()
	#hide()
	var image: Image = texture.get_image()
	texture = ImageTexture.create_from_image(image)
	image = texture.get_image()
	image.resize(256, 256, Image.INTERPOLATE_NEAREST)
	#image.resize(256, (256.0 / float(image.get_width())) * image.get_height())
	var data_packed = image.get_data()
	var data = Array(data_packed)
	#for i in range(0, 300, 3):
		#print(str(data[i + 1]) + " " + str(data[i + 1]) + " " + str(data[i + 2]))
	#await get_tree().create_timer(1000).timeout
	#return {}
	print(texture)
	print(image.get_format())
	print(ImageTexture.create_from_image(image).get_format())
	
	data = format_data_for_analysis(data)
	
	
	
	var seed_index: int = -1
	
	var largest_island_size = 0
	var largest_island_seed_index: int
	var largest_island = []
	
	print("Building Islands")
	for i in range(100):
	#for i in range(data.size()):
	#while true:
		seed_index = get_first_empty_index(data)
		if seed_index < 0:
			break
		var empty_island = fill_empty_island(data, seed_index, Vector2i(image.get_width(), image.get_height()))
		if empty_island.size() > largest_island_size:
			largest_island_seed_index = seed_index
			largest_island_size = empty_island.size()
			largest_island = empty_island
		#for index in empty_island:
			#print(data[index])
		for index in empty_island:
			data[index] = PIXEL_STATUS.PREVIOUSLY_SEARCHED
		#for index in empty_island:
			#print(data[index])
		#print(seed_index)
		#print(empty_island.size())
		#print("")
	
	print("Done building islands")
	
	if largest_island_size <= 0:
		#There is no island on this image
		print("No islands on image")
		return {"image": image, "largest_island_size_percentage": 0, "largest_island_seed_index": largest_island_seed_index, "max_width": 0, "min_width": 0, "mean_width": 0, "median_width": 0}
	
	print("Largest Island - size: " + str(largest_island_size), ", seed_index: " + str(largest_island_seed_index))
	
	var lines : Dictionary = {}
	print("Beginning data cleanup")
	for index in largest_island:
		#Cleanup
		data[index] = PIXEL_STATUS.PART_OF_LARGEST_ISLAND
		
		#Get lines
		var pixel_coords : Vector2i = index_to_coords(index, Vector2i(image.get_width(), image.get_height()))
		if not lines.has(pixel_coords.y):
			#This is the first pixel in the row
			lines[pixel_coords.y] = []
		lines[pixel_coords.y].append(pixel_coords.x)
	
	print("Beginning data analysis")
	
	var max_line_width : float = 0
	var min_line_width : float = image.get_width()
	var mean_line_width : float = 0
	var mean_line_start : float = 0
	var mean_line_end : float = 0
	var line_sizes : Array = []
	for key in lines.keys():
		lines[key].sort()
		var line_size = lines[key].size()
		
		#Max
		max_line_width = max(max_line_width, line_size)
		
		#Min
		min_line_width = min(min_line_width, line_size)
		
		#Mean
		mean_line_width += line_size
		
		#Median
		line_sizes.append(lines[key].size())
		
		#Mean start / end
		mean_line_start += lines[key][0]
		mean_line_end += lines[key][lines[key].size() - 1]
	
	#Stats cleanup
	mean_line_width /= lines.size()
	mean_line_start /= lines.size()
	mean_line_end /= lines.size()
	
	line_sizes.sort()
	var median_line_width : float = line_sizes[int(line_sizes.size() / 2.0)]
	
	#Turn stats into percentages instead of raw pixels
	max_line_width /= image.get_width()
	min_line_width /= image.get_width()
	mean_line_width /= image.get_width()
	median_line_width /= image.get_width()
	mean_line_start /= image.get_width()
	mean_line_end /= image.get_width()
	var mean_line_middle = mean_line_end - mean_line_start
	var largest_island_size_percentage = float(largest_island_size) / float(image.get_width() * image.get_height())
	
	print("Beginning image cleanup")
	
	#Image cleanup
	#print(data.size())
	data = format_data_for_rendering(data)
	#print(data.size())
	#print(data.slice(0, 100))
	#print(data.slice(-100, -1))
	#data = data.slice(0, -2)
	var flood_image: Image = Image.create_from_data(image.get_width(), image.get_height(), image.has_mipmaps(), image.get_format(), PackedByteArray(data))
	flood_image.resize(viewport.get_texture().get_image().get_width(), viewport.get_texture().get_image().get_height())
	
	print("Returning data")
	
	return {"image": flood_image, "largest_island_size_percentage": largest_island_size_percentage, "largest_island_seed_index": largest_island_seed_index, "max_width": max_line_width, "min_width": min_line_width, "mean_width": mean_line_width, "median_width": median_line_width, "mean_middle": mean_line_middle, "mean_start": mean_line_start, "mean_end": mean_line_end}
	#return {"image": flood_image, "largest_island_size_percentage": largest_island_size_percentage, "largest_island_seed_index": largest_island_seed_index, "max_width": max_line_width, "min_width": min_line_width, "mean_width": mean_line_width, "median_width": median_line_width, "mean_middle": mean_line_middle}
	#return {"image": flood_image, "largest_island_size_percentage": largest_island_size_percentage, "largest_island_seed_index": largest_island_seed_index, "max_width": max_line_width, "min_width": min_line_width, "mean_width": mean_line_width, "median_width": median_line_width, "mean_start": mean_line_start, "mean_end": mean_line_end}


#Returns the pixel indices of a new empty island
#Flood fills out from the seed index
func fill_empty_island(data: Array, seed_index: int, image_dimensions: Vector2i) -> Array:
	var island_indices = [seed_index]
	var frontier = [seed_index]
	var neighbor_indices: Array
	
	#print(island_indices)
	
	while true:
		neighbor_indices = get_neighbors(frontier.pop_front(), image_dimensions)
		
		for n_index in neighbor_indices:
			if data[n_index] == PIXEL_STATUS.EMPTY:
				data[n_index] = PIXEL_STATUS.PREVIOUSLY_SEARCHED
				frontier.push_back(n_index)
				island_indices.append(n_index)
		
		if frontier.size() == 0:
			break
	
	return island_indices

#Returns an array of indices of the neighboring pixels of a given index
func get_neighbors(index: int, image_dimensions: Vector2i) -> Array:
	var neighbor_indices = []
	
	var current_pixel_coords: Vector2i = index_to_coords(index, image_dimensions)
	
	for neighbor_delta_coord in [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)]:
		var neighbor_index = coords_to_index(neighbor_delta_coord + current_pixel_coords, image_dimensions)
		if neighbor_index >= 0:
			neighbor_indices.append(neighbor_index)
	
	return neighbor_indices

#Returns the coordinates of a pixel, given its index
func index_to_coords(index: int, image_dimensions: Vector2i) -> Vector2i:
	if index < 0 or index > image_dimensions.x * image_dimensions.y:
		return Vector2i(-1, -1)
	var y = floor(float(index) / float(image_dimensions.x))
	var x = index - y * image_dimensions.x
	return Vector2i(x, y)

#Returns the index of a pixel, given its coordinates
func coords_to_index(coords: Vector2i, image_dimensions: Vector2i) -> int:
	if coords.x < 0 or coords.y < 0 or coords.x >= image_dimensions.x or coords.y >= image_dimensions.y:
		return -1
	return coords.x + coords.y * image_dimensions.x

#Gets the array of the first emtpy pixel
func get_first_empty_index(data: Array) -> int:
	for i in range(data.size()):
		if data[i] == PIXEL_STATUS.EMPTY:
			return i
	return -1

#Replaces the 255s, etc. with the PIXEL_STATUS enum values
func format_data_for_analysis(data: Array) -> Array:
	var new_data = []
	var raw_pixel_size = 4		#3 if using forward+ rendering, 4 if using compatability
	for i in range(0, data.size(), raw_pixel_size):
		var datum_color = data.slice(i, i + 3)
		match datum_color:
			[0, 0, 0]:
				new_data.append(PIXEL_STATUS.EMPTY)
			[255, 255, 255]:
				new_data.append(PIXEL_STATUS.FULL)
			_:
				new_data.append(PIXEL_STATUS.EMPTY)
				#printerr("Bad datum for analysis " + str(datum_color))
	
	return new_data

#Replaces the PIXEL_STATUS enum values, etc. with the 255s
#Basically undoes format_data_for_analysis
func format_data_for_rendering(data: Array) -> Array:
	var new_data = []
	for i in range(data.size()):
		match data[i]:
			PIXEL_STATUS.EMPTY:
				new_data.append(0)
				new_data.append(0)
				new_data.append(0)
				new_data.append(255)		#If using compatability rendering
			PIXEL_STATUS.FULL:
				new_data.append(0)
				new_data.append(0)
				new_data.append(0)
				new_data.append(255)		#If using compatability rendering
			PIXEL_STATUS.PREVIOUSLY_SEARCHED:
				new_data.append(0)
				new_data.append(0)
				new_data.append(0)
				new_data.append(255)		#If using compatability rendering
			PIXEL_STATUS.PART_OF_LARGEST_ISLAND:
				new_data.append(255)
				new_data.append(0)
				new_data.append(0)
				new_data.append(255)		#If using compatability rendering
			_:
				printerr("Bad datum for rendering " + str(data[i]))
	
	return new_data

#Used by the user to fine tune the thresholding value for processing
func threshold_value_changed(value):
#func _on_processing_threshold_slider_value_changed(value):
	#threshold_rect.material.set_shader_parameter("threshold", int(value))
	threshold_rect.material.set_shader_parameter("threshold", (float(value) / 256.0))
