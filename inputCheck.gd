extends VBoxContainer

@onready var input = $UsernameInput
@onready var host_button = $HostButton
@onready var join_button = $JoinButton
@onready var start_button = $StartGame

func _ready():
	input.text_changed.connect(_on_input_text_changed)
	_on_input_text_changed(input.text)

func _on_input_text_changed(new_text: String):
	host_button.disabled = new_text.strip_edges() == ""
	join_button.disabled = new_text.strip_edges() == ""
	start_button.disabled = new_text.strip_edges() == ""
