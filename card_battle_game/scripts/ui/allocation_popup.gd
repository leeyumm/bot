# allocation_popup.gd — 矛/盾分配弹窗
extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var value_label: Label = $PanelContainer/VBoxContainer/ValueLabel
@onready var spear_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/SpearButton
@onready var shield_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/ShieldButton

var _current_value: int = 0
var _is_player: bool = true

func _ready() -> void:
	EventBus.allocation_requested.connect(_on_allocation_requested)
	spear_btn.pressed.connect(_on_spear_pressed)
	shield_btn.pressed.connect(_on_shield_pressed)
	panel.visible = false

func _on_allocation_requested(value: int, is_player: bool) -> void:
	if not is_player:
		return  # AI 不显示弹窗
	_current_value = value
	_is_player = is_player
	value_label.text = "配对成功！点数: %d\n选择加成方向:" % value
	spear_btn.text = "矛 +%d" % value
	shield_btn.text = "盾 +%d" % value
	panel.visible = true

func _on_spear_pressed() -> void:
	_choose(true)

func _on_shield_pressed() -> void:
	_choose(false)

func _choose(to_spear: bool) -> void:
	panel.visible = false
	EventBus.allocation_chosen.emit(to_spear, _current_value, _is_player)
