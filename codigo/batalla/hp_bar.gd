extends Control
class_name HpBar

@onready var creature_label: Label = $label
@onready var hp_label: Label = $hp_label
@onready var hp_bar: ProgressBar = $bar
@onready var exp_bar: ProgressBar = $exp_bar

func _ready() -> void:
	_style_hp_bar()
	_style_exp_bar()

func set_creature_name(creature_name: String) -> void:
	creature_label.text = creature_name

func set_hp(current_hp: int, max_hp: int) -> void:
	var safe_max: int = max(1, max_hp)
	hp_bar.max_value = safe_max
	hp_bar.value = clamp(current_hp, 0, safe_max)
	hp_label.text = "HP: %d / %d" % [clamp(current_hp, 0, safe_max), safe_max]

func set_exp_progress(current_exp: int, max_exp: int) -> void:
	var safe_max: int = max(1, max_exp)
	exp_bar.max_value = safe_max
	exp_bar.value = clamp(current_exp, 0, safe_max)

func set_exp_visible(is_visible: bool) -> void:
	exp_bar.visible = is_visible

func _style_hp_bar() -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.18, 0.78, 0.22)
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("background", background)

func _style_exp_bar() -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.html("#0000FF")
	fill.corner_radius_top_left = 1
	fill.corner_radius_top_right = 1
	fill.corner_radius_bottom_left = 1
	fill.corner_radius_bottom_right = 1
	exp_bar.add_theme_stylebox_override("fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.07, 0.07, 0.12, 0.9)
	background.corner_radius_top_left = 1
	background.corner_radius_top_right = 1
	background.corner_radius_bottom_left = 1
	background.corner_radius_bottom_right = 1
	exp_bar.add_theme_stylebox_override("background", background)
