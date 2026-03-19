# hud.gd — 战斗中 HUD 显示
extends CanvasLayer

@onready var player_hp_label: Label = $MarginContainer/HBoxContainer/PlayerPanel/VBoxContainer/HPLabel
@onready var player_spear_label: Label = $MarginContainer/HBoxContainer/PlayerPanel/VBoxContainer/SpearLabel
@onready var player_shield_label: Label = $MarginContainer/HBoxContainer/PlayerPanel/VBoxContainer/ShieldLabel
@onready var opponent_hp_label: Label = $MarginContainer/HBoxContainer/OpponentPanel/VBoxContainer/HPLabel
@onready var opponent_spear_label: Label = $MarginContainer/HBoxContainer/OpponentPanel/VBoxContainer/SpearLabel
@onready var opponent_shield_label: Label = $MarginContainer/HBoxContainer/OpponentPanel/VBoxContainer/ShieldLabel
@onready var turn_label: Label = $TurnLabel
@onready var info_label: Label = $InfoLabel

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.allocation_chosen.connect(_on_allocation_changed)
	EventBus.battle_resolved.connect(_on_battle_resolved)
	EventBus.game_over.connect(_on_game_over)
	_update_display()

func _process(_delta: float) -> void:
	_update_display()

func _update_display() -> void:
	player_hp_label.text = "HP: %d/%d" % [GameState.player_hp, GameState.MAX_HP]
	player_spear_label.text = "矛: %d" % GameState.player_spear
	player_shield_label.text = "盾: %d" % GameState.player_shield
	opponent_hp_label.text = "HP: %d/%d" % [GameState.opponent_hp, GameState.MAX_HP]
	opponent_spear_label.text = "矛: %d" % GameState.opponent_spear
	opponent_shield_label.text = "盾: %d" % GameState.opponent_shield

func _on_turn_started(is_player: bool) -> void:
	turn_label.text = "你的回合" if is_player else "对手回合"

func _on_allocation_changed(_to_spear: bool, _value: int, _is_player: bool) -> void:
	_update_display()

func _on_battle_resolved(player_dmg: int, opponent_dmg: int) -> void:
	info_label.text = "你受到 %d 伤害 | 对手受到 %d 伤害" % [player_dmg, opponent_dmg]
	info_label.visible = true
	await get_tree().create_timer(2.0).timeout
	info_label.visible = false

func _on_game_over(player_won: bool) -> void:
	turn_label.text = "你赢了！" if player_won else "你输了..."
	turn_label.add_theme_font_size_override("font_size", 48)
