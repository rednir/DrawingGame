extends Control


onready var slider_volume = $SliderVolume


signal back


func _ready():
	$ButtonBack.connect("pressed", self, "on_button_back_pressed")

	slider_volume.value = 5



func on_button_back_pressed():
	emit_signal("back")