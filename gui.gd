class_name GUI extends Control

@export var URL_EDIT: TextEdit
@export var FILENAME_EDIT: TextEdit
@export var AUDIO_BITRATE_EDIT: TextEdit
@export var VIDEO_BITRATE_LIST: ItemList
@export var FORMAT_LIST: ItemList
@export var OUTPUT_CONSOLE: Label
@export var penguin: TextureRect
@export var ani: AnimatedSprite2D

@export var timestamp_l_s: SpinBox
@export var timestamp_l_m: SpinBox
@export var timestamp_l_h: SpinBox
@export var timestamp_r_s: SpinBox
@export var timestamp_r_m: SpinBox
@export var timestamp_r_h: SpinBox


@onready var penguin_image = preload("res://penguin.jpg") as Texture
@onready var red_eye_penguin_image = preload("res://memed-io-output (1).jpeg") as Texture

var current_quality := "1080" as String
var current_format := "mp4" as String

var is_timestamp_from = true

var DEFAULT_AUDIO_BITRATE := "128" as String


func _ready() -> void:
	FORMAT_LIST.select(0)
	VIDEO_BITRATE_LIST.select(5)


func _on_button_pressed() -> void:
	ani.visible = false
	ani.stop()
	penguin.texture = penguin_image

	var args := PackedStringArray()
	args.append("yt-dlp.exe")


	# url
	args.append(URL_EDIT.text)

	# format
	var indeces := FORMAT_LIST.get_selected_items() as PackedInt32Array
	var format := FORMAT_LIST.get_item_text(indeces[0]).to_lower() as String

	var video_indeces := VIDEO_BITRATE_LIST.get_selected_items() as PackedInt32Array
	var video_quality := VIDEO_BITRATE_LIST.get_item_text(video_indeces[0]) as String
	var formatted_video_quality := video_quality.split("p")[0] as String

	match format:
		"mp4":
			args.append("-S")
			if formatted_video_quality == "1440" or formatted_video_quality == "2160":
					args.append("vcodec:vp9,res:"+formatted_video_quality+",acodec:opus")
					args.append("--recode-video")
					args.append("mp4")
			else:
					args.append("vcodec:h264,res:"+formatted_video_quality+",acodec:m4a")
		"webm":
			args.append("-S")
			args.append("vcodec:vp9,res:"+formatted_video_quality+",acodec:opus")
		_:
			args.append("-x")
			args.append("--audio-format")
			args.append(format)
			args.append("--audio-quality")
			if AUDIO_BITRATE_EDIT.text == "":
				args.append(DEFAULT_AUDIO_BITRATE)
			else:
				args.append(AUDIO_BITRATE_EDIT.text)

	var timestamps := _convert_boxes_to_seconds() as Vector2i
	if not timestamps == Vector2i(0, 0):
		args.append("--download-sections")
		args.append("*" + str(timestamps.x) + "-" + str(timestamps.y))

	# file name
	args.append("-o " + format_file_name(format, FILENAME_EDIT.text))

	var output := [] as Array[String]

	#TODO switch to threads
	OUTPUT_CONSOLE.text = "Downloading...\n\ndon't worry if the program temporarily freezes."
	await get_tree().create_timer(0.1).timeout

	#TODO jesus christ please refactor
	OS.execute("wine", args, output, true)
	if output:
		OUTPUT_CONSOLE.text = ""
		var is_error := true
		for line: String in output:
			if line.contains("[youtube] Extracting URL"):
				is_error = false
				break
			OUTPUT_CONSOLE.text += line
		if is_error:
			return
	OUTPUT_CONSOLE.text = "Download completed!"
	penguin.texture = red_eye_penguin_image
	ani.play()
	ani.visible = true


func _convert_boxes_to_seconds() -> Vector2i:
	var x = int(timestamp_l_h.value * 3600 + timestamp_l_m.value * 60 + timestamp_l_s.value)
	var y = int(timestamp_r_h.value * 3600 + timestamp_r_m.value * 60 + timestamp_r_s.value)
	return Vector2i(x, y)


func format_file_name(format: String, file_name: String) -> String:
	var formatted_file_name := file_name
	if not file_name.ends_with(format):
		formatted_file_name += "." + format
	return formatted_file_name


func _on_video_list_item_selected(index: int) -> void:
	current_quality = VIDEO_BITRATE_LIST.get_item_text(index).split("p")[0]
	if current_quality == "1440" or current_quality == "2160":
		if current_format == "mp4":
			OUTPUT_CONSOLE.text = "⚠️ Warning: Videos with resolutions higher than 1080p need to be downloaded \
via the .webm format.\nUsing the .mp4 format, the video will get converted from .webm to .mp4 automatically.\n\
The process of conversion can take up multiple minutes or hours, depending on your system and the length of the video."
	else:
		OUTPUT_CONSOLE.text = ""


func _on_format_list_item_selected(index: int) -> void:
	OUTPUT_CONSOLE.text = ""
	VIDEO_BITRATE_LIST.set_item_text(-1, "2160p (4K/UHD)")
	VIDEO_BITRATE_LIST.set_item_text(-2, "1440p (2K/QHD)")
	for i in range(0, VIDEO_BITRATE_LIST.item_count):
			VIDEO_BITRATE_LIST.set_item_disabled(i, false)

	current_format = FORMAT_LIST.get_item_text(index).to_lower()
	if current_format == "mp4":
		if current_quality == "1440" or current_quality == "2160":
			OUTPUT_CONSOLE.text = "⚠️ Warning: Videos with resolutions higher than 1080p need to be downloaded \
via the .webm format.\nUsing the .mp4 format, the video will get converted from .webm to .mp4 automatically.\n\
The process of conversion can take up multiple minutes or hours, depending on your system and the length of the video."
		VIDEO_BITRATE_LIST.set_item_text(-1, "2160p (4K/UHD) ⚠️")
		VIDEO_BITRATE_LIST.set_item_text(-2, "1440p (2K/QHD) ⚠️")

	elif current_format == "mp3" or current_format =="wav":
		for i in range(0, VIDEO_BITRATE_LIST.item_count):
			VIDEO_BITRATE_LIST.set_item_disabled(i, true)

#https://youtu.be/T6RglIqOc9A?t=94
func _on_url_edit_text_changed() -> void:
	if URL_EDIT.text.contains("?t="):
		var seconds = int(URL_EDIT.text.rsplit("?t=")[1])
		@warning_ignore("integer_division")
		var hours = seconds / 3600
		seconds = seconds - hours * 3600
		@warning_ignore("integer_division")
		var minutes = seconds / 60
		seconds = seconds - minutes * 60

		if is_timestamp_from:
			timestamp_l_h.value = hours
			timestamp_l_m.value = minutes
			timestamp_l_s.value = seconds
		else:
			timestamp_r_h.value = hours
			timestamp_r_m.value = minutes
			timestamp_r_s.value = seconds

		is_timestamp_from = !is_timestamp_from
