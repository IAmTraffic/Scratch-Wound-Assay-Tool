extends Control

const margins = Vector2(50, 50)
const data_point_size = 10
const data_point_color = Color.BLUE
const line_width = 5
const line_color = Color.GREEN



func graph_data(data):
	var percentages = []
	var data_point_locations = []
	for datum in data:
		percentages.append(datum.size_percentage)
	
	print(percentages)
	
	#Convert raw data to display coords
	print(get_transform())
	var separation = get_rect().size.x / percentages.size()
	
	var max_percentage = percentages.max()
	var min_percentage = percentages.min()
	
	var max_display_percentage = max_percentage + ((max_percentage - min_percentage) * 0.1)
	var min_display_percentage = max(0, min_percentage - ((max_percentage - min_percentage) * 0.1))
	
	for i in range(percentages.size()):
		data_point_locations.append(Vector2(separation * i, get_rect().size.y * inverse_lerp(max_display_percentage, min_display_percentage, percentages[i])) + margins)
	
	#Display the data
	
	for i in range(data_point_locations.size() - 1):
		var line : Line2D = Line2D.new()
		add_child(line)
		line.points = PackedVector2Array([data_point_locations[i], data_point_locations[i + 1]])
		line.width = line_width
		line.default_color = line_color
	
	for data_point_location in data_point_locations:
		var polygon : Polygon2D = Polygon2D.new()
		add_child(polygon)
		polygon.polygon = PackedVector2Array([Vector2(-data_point_size / 2, -data_point_size / 2), Vector2(data_point_size / 2, -data_point_size / 2), Vector2(data_point_size / 2, data_point_size / 2), Vector2(-data_point_size / 2, data_point_size / 2)])
		polygon.position = data_point_location
		polygon.color = data_point_color
