extends Control

@onready var viewport_container = $VBoxContainer/ImageProcessing/SubViewportContainer
@onready var texture_rect = $VBoxContainer/ImageProcessing/SubViewportContainer/SubViewport/TextureRect
@onready var file_dialog =$VBoxContainer/ImageProcessing/FileDialog
@onready var image_processor = $VBoxContainer/ImageProcessing
@onready var progress_label = %ProgressLabel
@onready var post_process_options = %"Post Process Options"
@onready var save_csv_file_dialog = %SaveCSVFileDialog
@onready var save_images_file_dialog = %SaveImagesFileDialog
@onready var sub_viewport = %SubViewport
@onready var threshold_adjustments = %"Threshold Adjustments"
@onready var flood_image_display = %"Flood Image Display"
@onready var threshold_input_field = %ThresholdInputField
@onready var processing_threshold_slider = %ProcessingThresholdSlider
@onready var post_progress_label = %"Progress Label"
@onready var threshold_rect = %ThresholdRect

signal image_saved(thread: Thread)

var DATA = []
var CURRENT_IMAGE_DATA = {}
var CURRENT_IMAGE_INDEX = 0
const DOWNLOAD_FLOOD_OVERLAY_MIX_WEIGHT = 0.8


func _ready():
	connect("image_saved", _on_img_save_thread_complete)

func _on_load_btn_pressed():
	file_dialog.show()

var PATHS = []
func _on_file_dialog_files_selected(paths):
	CURRENT_IMAGE_INDEX = 0
	PATHS = []
	if paths.size() == 0:
		return
	
	threshold_input_field.text = "40"
	
	image_processor.show()
	post_process_options.hide()
	
	threshold_adjustments.show()
	flood_image_display.show()
	
	
	paths = Array(paths)
	for i in range(paths.size()):
		paths[i] = paths[i].replace("\\", "/")
	PATHS = paths
	_on_threshold_input_field_text_submitted("40")
	
	#render_image_flood()
	
	#Continues in _on_confirm_threshold_btn_pressed

#Continuation of _on_file_dialog_files_selected, once the threshold is locked in
#At this point, we do the actual calculations
#func _on_confirm_threshold_btn_pressed():
	#threshold_adjustments.hide()
	#flood_image_display.hide()
	#progress_label.show()
	#
	#DATA = []
	#for i in range(PATHS.size()):
		#progress_label.text = "Processing image " + str(i + 1) + "/" + str(PATHS.size())
		#
		#var path = PATHS[i]
		#
		#var filename = path.rsplit("/", true, 1)
		#if filename.size() == 1:
			#filename = str(path.rsplit("\\", true, 1)[1])
		#else:
			#filename = filename[1]
		#
		#var datum = {
			#"filename": filename,
			#"filepath": path,
			#"threshold": int(256 * threshold_rect.material.get_shader_parameter("threshold"))
		#}
		#
		#var flood_data = await get_scratch_data(path)
		#
		##print(flood_data)
		#
		#var original_img = Image.load_from_file(path)
		#flood_data.image.resize(original_img.get_width(), original_img.get_height())
		#
		#datum.flood_image = flood_data.image
		#datum.scratch_percentage_of_image = flood_data.largest_island_size_percentage
		#datum.max_width = flood_data.max_width
		#datum.min_width = flood_data.min_width
		#datum.mean_width = flood_data.mean_width
		#datum.median_width = flood_data.median_width
		#
		#print(datum)
		#DATA.append(datum)
		##DATA.append({"filename": filename, "filepath": path, "flood_image": flood_data.image, "scratch_percentage_of_image": flood_data.largest_island_size_percentage, "max_width": flood_data.max_width, "min_width": flood_data.min_width, "mean_width": flood_data.mean_width, "median_width": flood_data.median_width})
	#
	#
	#image_processor.hide()
	#progress_label.hide()
	#post_process_options.show()

func _on_next_image_btn_pressed():
	if CURRENT_IMAGE_INDEX >= PATHS.size():
		image_processor.hide()
		progress_label.hide()
		post_process_options.show()
		return
	
	var path = PATHS[CURRENT_IMAGE_INDEX]
	
	var filename = path.rsplit("/", true, 1)
	if filename.size() == 1:
		filename = str(path.rsplit("\\", true, 1)[1])
	else:
		filename = filename[1]
	
	var datum = {
		"filename": filename,
		"filepath": path,
		"threshold": int(256 * threshold_rect.material.get_shader_parameter("threshold"))
	}
	
	var flood_data = CURRENT_IMAGE_DATA
	if flood_data:
		var original_img = Image.load_from_file(path)
		flood_data.image.resize(original_img.get_width(), original_img.get_height())
		
		datum.flood_image = flood_data.image
		datum.scratch_percentage_of_image = flood_data.largest_island_size_percentage
		datum.max_width = flood_data.max_width
		datum.min_width = flood_data.min_width
		datum.mean_width = flood_data.mean_width
		datum.median_width = flood_data.median_width
		datum.mean_start = flood_data.mean_start
		datum.mean_end = flood_data.mean_end
		datum.mean_middle = flood_data.mean_middle
		
		print(datum)
		if CURRENT_IMAGE_INDEX >= DATA.size():
			DATA.append(datum)
		else:
			DATA[CURRENT_IMAGE_INDEX] = datum
	CURRENT_IMAGE_INDEX += 1
	
	if CURRENT_IMAGE_INDEX >= PATHS.size():
		image_processor.hide()
		progress_label.hide()
		post_process_options.show()
		return
	
	render_image_flood(CURRENT_IMAGE_INDEX)


func _on_prev_image_btn_pressed():
	if CURRENT_IMAGE_INDEX == 0:
		return
	
	CURRENT_IMAGE_INDEX -= 1
	render_image_flood(CURRENT_IMAGE_INDEX)

#Renders the flooded overlay on the given image path
func render_image_flood(index: int):
	if index >= PATHS.size():
		return
	var flood_data = await get_scratch_data(PATHS[index])
	if flood_data:
		var flood_image: Image = flood_data.image
		var flood_texture = ImageTexture.create_from_image(flood_image)
		
		flood_image_display.material.set_shader_parameter("flood_image", flood_texture)
		
		CURRENT_IMAGE_DATA = flood_data

func _on_threshold_input_field_text_submitted(new_text: String):
	if new_text.is_valid_int() and int(new_text) >= 0 and int(new_text) <= 256:
		render_image_flood(CURRENT_IMAGE_INDEX)
		viewport_container.threshold_value_changed(int(new_text))



#Gets the scratch data, given a path to an image
func get_scratch_data(path: String) -> Dictionary:
	var image := Image.load_from_file(path)
	print(path)
	texture_rect.texture = ImageTexture.create_from_image(image)
	flood_image_display.texture = ImageTexture.create_from_image(image)
	flood_image_display.material.set_shader_parameter("flood_image", null)
	
	
	return await viewport_container.get_flood_data()



func _on_csv_download_pressed():
	print("requesting csv download")
	
	save_csv_file_dialog.show()
	#Continued in _on_save_csv_file_dialog_file_selected


func _on_images_download_pressed():
	print("requesting download of markedup images")
	
	save_images_file_dialog.show()
	#Continued in _on_save_images_file_dialog_dir_selected


#Overlays the flood image on the base image for downloading
func mix_images(image_1: Image, image_2: Image) -> Image:
	var data_1 = Array(image_1.get_data())
	var data_2 = Array(image_2.get_data())
	
	if data_1.size() != data_2.size():
		printerr("Error mixing images. Image sizes don't match. Check resolution and file formats.")
		return image_1
	
	var mixed_data_array : Array = []
	
	for i in range(data_1.size()):
		mixed_data_array.append(lerp(data_1[i], data_2[i], DOWNLOAD_FLOOD_OVERLAY_MIX_WEIGHT))
	
	var mixed_image : Image = Image.create_from_data(image_1.get_width(), image_1.get_height(), image_1.has_mipmaps(), image_1.get_format(), PackedByteArray(mixed_data_array))
	return mixed_image

#Overlays vertical bars at the average scratch sides
func bar_image(image: Image, middle_x: float, radius_x: float, n, mean_start, mean_end) -> Image:
#func bar_image(image: Image, first_x: float, second_x: float) -> Image:
	var line_radius: int = int(image.get_width() / 200.0)
	var line_color = Color(0.0, 1.0, 0.0, 0.5)
	
	middle_x *= image.get_width()
	radius_x *= image.get_width()
	mean_start *= image.get_width()
	mean_end *= image.get_width()
	#first_x *= image.get_width()
	#second_x *= image.get_width()
	var first_x = mean_start
	var second_x = mean_end
	#var first_x = middle_x - radius_x
	#var second_x = middle_x + radius_x
	
	print(n)
	print(str(image.get_width()) + ", " + str(image.get_height()))
	print(str(mean_start) + " -> " + str(mean_end))
	print(mean_end - mean_start)
	print(middle_x)
	print(radius_x)
	print(first_x)
	print(second_x)
	print("")
	
	#image.fill_rect(Rect2i(Vector2i(middle_x - line_radius, 0), Vector2i(line_radius * 2.0, image.get_height())), Color(0.0, 0.0, 1.0))
	image.fill_rect(Rect2i(Vector2i(first_x - line_radius, 0), Vector2i(line_radius * 2, image.get_height())), line_color)
	image.fill_rect(Rect2i(Vector2i(second_x - line_radius, 0), Vector2i(line_radius * 2, image.get_height())), line_color)
	
	return image

func _on_save_csv_file_dialog_file_selected(path: String):
	post_progress_label.text = "Saving data: " + path
	post_progress_label.show()
	var column_names : Array = DATA[0].keys()
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(column_names))
	
	print(file)
	
	for datum in DATA:
		print(datum)
		var line : Array = []
		for key in datum.keys():
			line.append(datum[key])
		file.store_csv_line(PackedStringArray(line))
	print("out")
	file.close()
	
	await get_tree().create_timer(2.0).timeout
	post_progress_label.hide()

var threads: Dictionary
var thread_batch_size = 4
func _on_save_images_file_dialog_dir_selected(dir):
	threads = {}
	saved_imgs = 0
	post_progress_label.text = "Processing image " + str(saved_imgs) + " / " + str(DATA.size())
	post_progress_label.show()
	for i in range(DATA.size()):
		var thread := Thread.new()
		threads[i] = thread
	
	for i in range(min(threads.size(), thread_batch_size)):
		var thread: Thread = threads[i]
		thread.start(save_img_thread.bind(DATA[i], dir, i))
	
	
	print("images downloaded - " + dir)

func save_img_thread(datum: Dictionary, dir, thread_index: int) -> void:
	var new_filename: String = dir + "/" + datum.filename.get_basename() + " Overlay." + datum.filename.get_extension()
	print("Writing " + new_filename)
	var file_format_on_disk : Image.Format = Image.load_from_file(datum.filepath).get_format()
	datum.flood_image.convert(file_format_on_disk)
	var mixed_image: Image = mix_images(datum.flood_image, Image.load_from_file(datum.filepath))
	var bar_added_image: Image = bar_image(mixed_image, datum.mean_middle, datum.mean_width / 2.0, datum.filename, datum.mean_start, datum.mean_end)
	#var bar_added_image: Image = bar_image(mixed_image, datum.mean_start, datum.mean_end)
	var err = bar_added_image.save_png(new_filename)
	if err:
		printerr(err)
	call_deferred("emit_signal", "image_saved", thread_index, dir)

var saved_imgs = 0
func _on_img_save_thread_complete(thread_index: int, dir):
	var thread: Thread = threads[thread_index]
	thread.wait_to_finish()
	saved_imgs += 1
	
	post_progress_label.text = "Processing image " + str(saved_imgs) + " / " + str(DATA.size())
	
	#Start next thread, if it exits
	if(thread_index + thread_batch_size < threads.size()):
		threads[thread_index + thread_batch_size].start(save_img_thread.bind(DATA[thread_index + thread_batch_size], dir, thread_index + thread_batch_size))
	
	if saved_imgs >= DATA.size():
		await get_tree().create_timer(2.0).timeout
		post_progress_label.hide()



