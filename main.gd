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

signal image_saved(thread: Thread)

var DATA = []
const DOWNLOAD_FLOOD_OVERLAY_MIX_WEIGHT = 0.8

## TODO
# image processing should be multithreaded
	# and those threads should be culled in the threshold selection phase
# other optimisations?
# add gallery of processed images after processing / before downloading? 
#
# add bars to image to represent the edges of the scratch?

func _ready():
	connect("image_saved", _on_img_save_thread_complete)
	
	pass
	#DEBUG
#	_on_file_dialog_files_selected(["res://test scratch wound assay/Screenshot 2023-11-16 233333.png"])

func _on_load_btn_pressed():
	file_dialog.show()

#func _process(_delta):
	#DEBUGGING
	#if Input.is_action_pressed("ui_cancel"):
		#get_tree().quit()

var PATHS = []
func _on_file_dialog_files_selected(paths):
	PATHS = []
	if paths.size() == 0:
		return
	
	threshold_input_field.text = "40"
	
	image_processor.show()
	progress_label.show()
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
func _on_confirm_threshold_btn_pressed():
	threshold_adjustments.hide()
	flood_image_display.hide()
	
	DATA = []
	for i in range(PATHS.size()):
		progress_label.text = "Processing image " + str(i + 1) + "/" + str(PATHS.size())
		
		var path = PATHS[i]
		
		var flood_data = await get_scratch_data(path)
		
		print(flood_data)
		
		var filename = path.rsplit("/", true, 1)
		if filename.size() == 1:
			filename = str(path.rsplit("\\", true, 1)[1])
		else:
			filename = filename[1]
		
		var original_img = Image.load_from_file(path)
		flood_data.image.resize(original_img.get_width(), original_img.get_height())
		
		DATA.append({"filename": filename, "filepath": path, "flood_image": flood_data.image, "scratch_percentage_of_image": flood_data.largest_island_size_percentage, "max_width": flood_data.max_width, "min_width": flood_data.min_width, "mean_width": flood_data.mean_width, "median_width": flood_data.median_width})
	
	
	image_processor.hide()
	progress_label.hide()
	post_process_options.show()

#Renders the flooded overlay on the given image path
func render_image_flood():
	var flood_data = await get_scratch_data(PATHS[0])
	if flood_data:
		var flood_image: Image = flood_data.image
		var flood_texture = ImageTexture.create_from_image(flood_image)
		
		flood_image_display.material.set_shader_parameter("flood_image", flood_texture)

var input_field_just_changed = false	#Used to prevent cycle here:
#Used to update the render visualization upon threshold slider change
func _on_processing_threshold_slider_value_changed(value):
	if input_field_just_changed:
		input_field_just_changed = false
	else:
		threshold_input_field.text = str(value)
		#threshold_input_field.text = str(int(value * 256))
	render_image_flood()
#Used to update the render visualization upon threshold text input change
#func _on_threshold_input_field_text_changed(new_text: String):
func _on_threshold_input_field_text_submitted(new_text: String):
	if new_text.is_valid_int() and int(new_text) >= 0 and int(new_text) <= 256:
		render_image_flood()
		#Update the threshold value
		#input_field_just_changed = true
		#processing_threshold_slider.value = float(new_text) / 256.0
		processing_threshold_slider.value = int(new_text)



#Gets the scratch data, given a path to an image
func get_scratch_data(path: String) -> Dictionary:
	var image := Image.load_from_file(path)
	print(path)
	#sub_viewport.size = image.get_size()
	texture_rect.texture = ImageTexture.create_from_image(image)
#		flood_image_display.texture = viewport_container.get_node("SubViewport").get_texture()
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


func _on_save_images_file_dialog_dir_selected(dir):
	saved_imgs = 0
	post_progress_label.text = "Processing image " + str(saved_imgs) + " / " + str(DATA.size())
	post_progress_label.show()
	for datum in DATA:
		var thread := Thread.new()
		thread.start(save_img_thread.bind(datum, dir, thread))
	
	
	print("images downloaded - " + dir)

func save_img_thread(datum: Dictionary, dir, thread: Thread) -> void:
	var new_filename: String = dir + "/" + datum.filename.get_basename() + " Overlay." + datum.filename.get_extension()
	print("Writing " + new_filename)
	var file_format_on_disk : Image.Format = Image.load_from_file(datum.filepath).get_format()
	datum.flood_image.convert(file_format_on_disk)
	var new_image: Image = mix_images(datum.flood_image, Image.load_from_file(datum.filepath))
	var err = new_image.save_png(new_filename)
	if err:
		printerr(err)
	call_deferred("emit_signal", "image_saved", thread)

var saved_imgs = 0
func _on_img_save_thread_complete(thread: Thread):
	thread.wait_to_finish()
	saved_imgs += 1
	
	post_progress_label.text = "Processing image " + str(saved_imgs) + " / " + str(DATA.size())
	
	if saved_imgs >= DATA.size():
		await get_tree().create_timer(2.0).timeout
		post_progress_label.hide()
